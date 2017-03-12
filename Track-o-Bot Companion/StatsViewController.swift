//
//  SettingsViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 08.09.15.
//  Copyright (c) 2015 Julian Eberius.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//


import UIKit
import Charts


class StatsViewController: TrackOBotViewController, ChartViewDelegate {

    @IBOutlet weak var mainChartLabel: UILabel!
    @IBOutlet weak var mainChart: BarChartView!
    @IBOutlet weak var detailChartLabel: UILabel!
    @IBOutlet weak var detailChart: BarChartView!
    @IBOutlet weak var statTypeSegmentControl: UISegmentedControl!

    var decks: [Deck] = []

    var yNames: [String] = []
    var barColors: [UIColor] = []
    var detailYNames: [String] = []
    var detailBarColors: [UIColor] = []

    var selectedIndexMainChart: Int? = nil

    let heroColors = [
        UIColor(hue: 0.013, saturation: 0.73, brightness: 1.0, alpha: 1.0),
        UIColor(hue: 0.5806, saturation: 1, brightness: 0.86, alpha: 1.0),
        UIColor(hue: 0.0, saturation: 0.0, brightness: 0.3, alpha: 1.0),
        UIColor(hue: 0.1556, saturation: 0.57, brightness: 1, alpha: 1.0),
        UIColor(hue: 0.3111, saturation: 0.57, brightness: 0.84, alpha: 1.0),
        UIColor(hue: 0.0806, saturation: 0.72, brightness: 0.83, alpha: 1.0),
        UIColor(hue: 0.9222, saturation: 0.43, brightness: 0.82, alpha: 1.0),
        UIColor(hue: 0.5444, saturation: 0.56, brightness: 0.94, alpha: 1.0),
        UIColor(hue: 0.1333, saturation: 0.11, brightness: 1, alpha: 1.0)
    ]

    struct BarChartDataAndMetadata {
        let barChartData: BarChartData
        let colors: [UIColor]
        let yNames: [String]
        let filteredStats: [Stats]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainChart.noDataText = "Loading data ..."
        self.mainChart.infoTextColor = UIColor(colorLiteralRed: 0.882, green: 0.169, blue: 0.337, alpha: 1.0)
        self.detailChart.noDataText = "Select a class ..."
        self.detailChart.infoTextColor = UIColor(colorLiteralRed: 0.882, green: 0.169, blue: 0.337, alpha: 1.0)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resetCharts()
    }

    func resetCharts() {
        self.mainChart.highlightValue(nil)
        self.selectedIndexMainChart = nil
        self.detailChart.clear()
        self.updateDescriptionLabel()

        if (statTypeSegmentControl.selectedSegmentIndex == 0) {
            self.detailChart.noDataText = "Select a class ..."
            TrackOBot.instance.getByClassStats(statResultsCallback({ stats -> BarChartDataAndMetadata in
                let chartData = self.createHeroBarChartData(stats)
                self.updateMainChartState(colors: chartData.colors, yNames: chartData.yNames)
                return chartData
            }))
        } else {
            self.detailChart.noDataText = "Select a deck ..."
            TrackOBot.instance.getDecks({
                (result) in
                switch (result) {
                case .success(let decks):
                    self.decks = decks.flatMap { $0 }
                    break
                case .failure:
                    // TODO handle
                    return
                }
            })
            TrackOBot.instance.getByDeckStats(statResultsCallback({ stats -> BarChartDataAndMetadata in
                let chartData = self.createDeckBarChartData(stats)
                self.updateMainChartState(colors: chartData.colors, yNames: chartData.yNames)
                return chartData
            }))
        }
    }

    fileprivate func statResultsCallback<T: Stats>(_ barChartMapper:@escaping (([T])->BarChartDataAndMetadata)) -> ((Result<[T], TrackOBotAPIError>) -> ()) {
        return { (result:Result<[T], TrackOBotAPIError>) in
            switch result {
            case .success(let stats):
                let data = barChartMapper(stats)
                self.updateChart(self.mainChart, data: data.barChartData, stats: data.filteredStats)
                break
            case .failure(let err):
                switch err {
                case .credentialsMissing, .loginFailed(_):
                    self.performSegue(withIdentifier: "to_login", sender: self)
                default:
                    self.alert("Error", message: "Error retrieving statistics: \(err)")
                }
            }
        }
    }


    @IBAction func statTypeSegmentControlValueChanged(_ sender: UISegmentedControl) {
        resetCharts()
    }

    func updateMainChartState(colors: [UIColor], yNames: [String]) {
        self.barColors = colors
        self.yNames = yNames
    }

    func updateDetailChartState(colors: [UIColor], yNames: [String]) {
        self.detailBarColors = colors
        self.detailYNames = yNames
    }

    func createHeroBarChartData(_ stats: [ByClassStats]) -> BarChartDataAndMetadata {
        let barColors = self.heroColors
        let yNames = HEROES

        let data = HEROES.map { hero -> BarChartDataEntry in
            guard let d = stats.first(where: { st in st.hero == hero}), d.wins + d.losses > 0 else {
                return BarChartDataEntry(value: 0.0, xIndex: HEROES.index(of: hero)!)
            }
            let sum = d.wins + d.losses
            let val = Double(d.wins) / Double(sum) * 100.0
            return BarChartDataEntry(value: val, xIndex: HEROES.index(of: d.hero)!)
        }

        let ds = BarChartDataSet(yVals: data, label: "Win %")

        ds.setColors(barColors, alpha: 0.95)
        ds.highlightAlpha = 0.0
        ds.highlightLineWidth = 5.0

        ds.drawValuesEnabled = false
        let d = BarChartData(xVals: HEROES, dataSet: ds)

        return BarChartDataAndMetadata(barChartData: d, colors: barColors,
                                       yNames: yNames, filteredStats: stats)
    }

    func createDeckBarChartData(_ stats: [ByDeckStats]) -> BarChartDataAndMetadata {
        let filteredStats = stats.filter { d in d.wins + d.losses > 0 }
        let deckNames = filteredStats.map { d in d.deck as String }
        let yNames = deckNames
        let barColors = filteredStats.flatMap { (d) -> UIColor in
            guard let heroIdx = HEROES.index(of:d.hero) else {
                return UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            }
            return self.heroColors[heroIdx]
        }

        let data = filteredStats.map { (d) -> BarChartDataEntry in
            let sum = d.wins + d.losses
            guard sum > 0 else {
                return BarChartDataEntry(value: 0.0, xIndex: deckNames.index(of: d.deck)!)
            }
            let val = Double(d.wins) / Double(sum) * 100.0
            return BarChartDataEntry(value: val, xIndex: deckNames.index(of: d.deck)!)
        }
        let ds = BarChartDataSet(yVals: data, label: "Win %")

        ds.setColors(barColors, alpha: 1.0)
        ds.highlightAlpha = 0.0
        ds.highlightLineWidth = 5.0

        ds.drawValuesEnabled = false
        let d = BarChartData(xVals: deckNames, dataSet: ds)

        return BarChartDataAndMetadata(barChartData: d, colors: barColors,
                                       yNames: yNames, filteredStats: filteredStats)
    }

    func updateChart(_ chart: BarChartView, data: ChartData, stats: [Stats]) {
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.compact
            || stats.count > 9) {
            chart.xAxis.labelRotationAngle = 90
        } else {
            chart.xAxis.labelRotationAngle = 0
        }

        chart.xAxis.labelPosition = ChartXAxis.LabelPosition.bottom
        chart.xAxis.setLabelsToSkip(0)
        chart.xAxis.spaceBetweenLabels = 0

        chart.rightAxis.enabled = false
        chart.leftAxis.axisMaxValue = 100
        chart.leftAxis.axisMinValue = 0
        chart.leftAxis.labelCount = 5
        chart.leftAxis.forceLabelsEnabled = true
        chart.legend.enabled = false
        //chart.legend.position = ChartLegend.Position.AboveChartLeft
        chart.legend.horizontalAlignment = .left
        chart.legend.verticalAlignment = .top
        chart.legend.orientation = .horizontal
        chart.setScaleEnabled(false)
        chart.dragEnabled = false
        chart.descriptionText = ""
        chart.delegate = self
        chart.drawHighlightArrowEnabled = true
        chart.infoTextColor = UIColor(colorLiteralRed: 0.882, green: 0.169, blue: 0.337, alpha: 1.0)

        chart.marker = CustomChartMarker(chart: chart, stats: stats)

        chart.data = data
        chart.animate(yAxisDuration: 0.75)
    }

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        if (chartView == self.detailChart) {
            return
        }
        if (self.selectedIndexMainChart != entry.xIndex) {
            self.selectedIndexMainChart = entry.xIndex
            if (self.statTypeSegmentControl.selectedSegmentIndex == 0) {
                // TODO: fix bug in "as deck vs deck": always same stats
                TrackOBot.instance.getVsClassStats(self.yNames[entry.xIndex], onComplete: getVsStatsCallback({ stats -> BarChartDataAndMetadata in
                    let chartData = self.createHeroBarChartData(stats)
                    self.updateDetailChartState(colors: chartData.colors, yNames: chartData.yNames)
                    return chartData
                }))
            } else {
                let deckName = self.yNames[entry.xIndex]
                guard let deckId = self.decks.filter({ d in d.fullName == deckName }).first?.id else {
                    self.detailChart.clear()
                    self.detailChart.noDataText = "No statistics available for \"\(deckName)\""
                    self.updateDescriptionLabel()
                    // "Other xyz" has no id, and no stats can be retrieved from TrackOBot.com AFAIK
                    return
                }
                TrackOBot.instance.getVsDeckStats(deckId, onComplete: getVsStatsCallback({stats -> BarChartDataAndMetadata in
                    let chartData = self.createDeckBarChartData(stats)
                    self.updateDetailChartState(colors: chartData.colors, yNames: chartData.yNames)
                    return chartData
                }))
            }
        }
    }

    func getVsStatsCallback<T : Stats>(_ barChartMapper:@escaping (([T])->BarChartDataAndMetadata)) -> (Result<[T], TrackOBotAPIError>) -> () {
        return {
            (result: Result<[T], TrackOBotAPIError>) -> Void in
            switch result {
            case .success(let stats):
                let data = barChartMapper(stats)
                self.updateChart(self.detailChart, data: data.barChartData, stats: data.filteredStats)
                self.updateDescriptionLabel()
                break
            case .failure(let err):
                switch err {
                case .credentialsMissing, .loginFailed(_):
                    self.performSegue(withIdentifier: "to_login", sender: self)
                default:
                    self.alert("Error", message: "Error retrieving statistics: \(err)")
                }
            }
        }
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {

    }

    func updateDescriptionLabel() {
        guard let idx = self.selectedIndexMainChart else {
            self.detailChartLabel.text = "Win rates as ..."
            return
        }
        let attrString = NSMutableAttributedString(string: "Win rates as ")
        let labelString = NSAttributedString(string: "\(self.yNames[idx])",
                                            attributes: [NSForegroundColorAttributeName: self.barColors[idx],
                                                NSFontAttributeName: UIFont.boldSystemFont(ofSize: self.detailChartLabel.font.pointSize)])
        attrString.append(labelString)
        self.detailChartLabel.attributedText = attrString
    }

    @IBAction func unwindFromLogin(_ unwindSegue: UIStoryboardSegue) {

    }
}

class CustomChartMarker: ChartMarker
{
    let stats: [Stats]
    let chart: ChartViewBase!

    var strVal: String = ""
    var markerSize: CGSize = CGSize(width: 100, height: 15)

    init(chart:ChartViewBase, stats:[Stats])
    {
        self.chart = chart
        self.stats = stats
        super.init()
    }


    /// Draws the ChartMarker on the given position on the given context
    override func draw(context: CGContext, point: CGPoint)
    {
        let font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let attrsDictionary = [NSFontAttributeName:font] as [String : AnyObject]
        let str = NSAttributedString(string: strVal, attributes: attrsDictionary)
        let rectSize = str.boundingRect(with: CGSize(width: 300, height: 20), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        markerSize = rectSize.size

        var offset = CGPoint(x: 22, y: -19.0)
        if let width = chart.viewPortHandler?.chartWidth {
            if (point.x + rectSize.width + offset.x > width) {
                offset = CGPoint(x: -1.0 * rectSize.width, y: 0)
            }

        }

        if (point.y + offset.y < 0) {
            offset = CGPoint(x: 0, y: 0 )
        }

        let rect = CGRect(x: point.x + offset.x, y: point.y + offset.y, width: rectSize.width + 6, height: rectSize.height + 4)

        UIGraphicsPushContext(context)
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setFillColor(UIColor.white.cgColor.components!)
        context.fill(rect)
        context.stroke(rect)
        UIGraphicsPopContext()
        NSString(string: strVal).draw(in: rect.offsetBy(dx: 3, dy: 2), withAttributes: attrsDictionary)
    }

    /// This method enables a custom ChartMarker to update it's content everytime the MarkerView is redrawn according to the data entry it points to.
    ///
    /// - parameter highlight: the highlight object contains information about the highlighted value such as it's dataset-index, the selected range or stack-index (only stacked bar entries).
    override func refreshContent(entry: ChartDataEntry, highlight: ChartHighlight)
    {
        guard entry.xIndex < stats.endIndex else {
            strVal = "No data"
            return
        }
        let s = stats[entry.xIndex]
        let percentStr = String(format: "%.1f", entry.value)
        strVal = "\(percentStr)% (W: \(s.wins) / L: \(s.losses))"
    }

    override var size: CGSize {
        get { return markerSize }
    }
}
