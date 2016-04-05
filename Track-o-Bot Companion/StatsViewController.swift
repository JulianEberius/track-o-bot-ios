//
//  SettingsViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 08.09.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
//

import UIKit
import Charts

class StatsViewController: TrackOBotViewController, ChartViewDelegate {
    
    @IBOutlet weak var mainChartLabel: UILabel!
    @IBOutlet weak var mainChart: BarChartView!
    @IBOutlet weak var detailChartLabel: UILabel!
    @IBOutlet weak var detailChart: BarChartView!
    @IBOutlet weak var statTypeSegmentControl: UISegmentedControl!

    var yNames: [String] = []
    var decks: [Deck] = []
    var barColors: [UIColor] = []

    var selectedIndexMainChart: Int? = nil
    
    let heroColors = [
        UIColor(red: 167/255.0, green: 57.0/255.0, blue: 45.0/255.0, alpha: 1.0),
        UIColor(red: 48/255.0, green: 60.0/255.0, blue: 108.0/255.0, alpha: 1.0),
        UIColor(red: 37/255.0, green: 32.0/255.0, blue: 24.0/255.0, alpha: 1.0),
        UIColor(red: 235/255.0, green: 154.0/255.0, blue: 68.0/255.0, alpha: 1.0),
        UIColor(red: 35.0/255.0, green: 70.0/255.0, blue: 30.0/255.0, alpha: 1.0),
        UIColor(red: 108/255.0, green: 68.0/255.0, blue: 30.0/255.0, alpha: 1.0),
        UIColor(red: 88/255.0, green: 50.0/255.0, blue: 68.0/255.0, alpha: 1.0),
        UIColor(red: 45/255.0, green: 83.0/255.0, blue: 125.0/255.0, alpha: 1.0),
        UIColor(red: 250/255.0, green: 244/255.0, blue: 220.0/255.0, alpha: 1.0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainChart.noDataText = "Loading data ..."
        self.detailChart.noDataText = "Select a class ..."
    }


    override func viewWillAppear(animated: Bool) {
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
            TrackOBot.instance.getByClassStats(statResultsCallback(self.createHeroBarChartData))
        } else {
            self.detailChart.noDataText = "Select a deck ..."
            TrackOBot.instance.getByDeckStats(statResultsCallback(self.createDeckBarChartData))
            TrackOBot.instance.getDecks({
                (result) in
                switch (result) {
                case .Success(let decks):
                    self.decks = decks.flatMap { $0 }
                    break
                case .Failure:
                    // TODO handle
                    return
                }
            })
        }
    }

    private func statResultsCallback<T: Stats>(barChartMapper:([T]->BarChartData)) -> (Result<[T], TrackOBotAPIError> -> ()) {
        return { (result:Result<[T], TrackOBotAPIError>) in
            switch result {
            case .Success(let stats):
                let data = barChartMapper(stats)
                self.updateChart(self.mainChart, data: data, stats: stats)
                break
            case .Failure(let err):
                switch err {
                case .CredentialsMissing, .LoginFaild(_):
                    self.performSegueWithIdentifier("to_login", sender: self)
                default:
                    print("what")
                }
            }
        }
    }


    @IBAction func statTypeSegmentControlValueChanged(sender: UISegmentedControl) {
        resetCharts()
    }
    
    func createHeroBarChartData(stats: [ByClassStats]) -> BarChartData {
        self.barColors = self.heroColors
        self.yNames = HEROES

        let data = stats.map { (d) -> BarChartDataEntry in
            let sum = d.wins + d.losses
            guard sum > 0 else {
                return BarChartDataEntry(value: 0.0, xIndex: HEROES.indexOf(d.hero)!)
            }
            let val = Double(d.wins) / Double(sum) * 100.0
            return BarChartDataEntry(value: val, xIndex: HEROES.indexOf(d.hero)!)
        }
        let ds = BarChartDataSet(yVals: data, label: "Win %")

        ds.setColors(self.barColors, alpha: 0.95)
        ds.highlightAlpha = 0.0
        ds.highlightLineWidth = 5.0
        
        ds.drawValuesEnabled = false
        let d = BarChartData(xVals: HEROES, dataSet: ds)


        return d
    }

    func createDeckBarChartData(stats: [ByDeckStats]) -> BarChartData {
        let decks = stats.map { d in d.deck as String }
        self.yNames = decks
        self.barColors = ChartColorTemplates.liberty()

        let data = stats.map { (d) -> BarChartDataEntry in
            let sum = d.wins + d.losses
            guard sum > 0 else {
                return BarChartDataEntry(value: 0.0, xIndex: decks.indexOf(d.deck)!)
            }
            let val = Double(d.wins) / Double(sum) * 100.0
            return BarChartDataEntry(value: val, xIndex: decks.indexOf(d.deck)!)
        }
        let ds = BarChartDataSet(yVals: data, label: "Win %")

        ds.setColors(self.barColors, alpha: 1.0)
        ds.highlightAlpha = 0.0
        ds.highlightLineWidth = 5.0

        ds.drawValuesEnabled = false
        let d = BarChartData(xVals: decks, dataSet: ds)


        return d
    }
    
    func updateChart(chart: BarChartView, data: ChartData, stats: [Stats]) {
        if (self.view.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact) {
            chart.xAxis.labelRotationAngle = 90
        } else {
            chart.xAxis.labelRotationAngle = 0
        }
        
        chart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.Bottom
        chart.xAxis.setLabelsToSkip(0)
        chart.xAxis.spaceBetweenLabels = 0

        chart.rightAxis.enabled = false
        chart.leftAxis.customAxisMax = 100
        chart.leftAxis.customAxisMin = 0
        chart.leftAxis.labelCount = 5
        chart.leftAxis.forceLabelsEnabled = true
        chart.legend.enabled = false
        chart.legend.position = ChartLegend.ChartLegendPosition.AboveChartLeft
        chart.setScaleEnabled(false)
        chart.dragEnabled = false
        chart.descriptionText = ""
        chart.delegate = self
        chart.drawHighlightArrowEnabled = true
    
        chart.marker = CustomChartMarker(chart: chart, stats: stats)

        chart.data = data
        chart.animate(yAxisDuration: 0.75)
    }
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        if (chartView == self.detailChart) {
            return
        }
        if (self.selectedIndexMainChart != entry.xIndex) {
            self.selectedIndexMainChart = entry.xIndex
            if (self.statTypeSegmentControl.selectedSegmentIndex == 0) {
                TrackOBot.instance.getVsClassStats(self.yNames[entry.xIndex], onComplete: getVsStatsCallback(self.createHeroBarChartData))
            } else {
                let deckName = self.yNames[entry.xIndex]
                let di = self.decks.filter { d in d.name == deckName }.first?.id
                guard let deckId = di else {
                    // TODO: handle
                    return
                }
                TrackOBot.instance.getVsDeckStats(deckId, onComplete: getVsStatsCallback(self.createDeckBarChartData))
            }
        }
    }

    func getVsStatsCallback<T : Stats>(barChartMapper:([T]->BarChartData)) -> (Result<[T], TrackOBotAPIError>) -> () {
        return {
            (result: Result<[T], TrackOBotAPIError>) -> Void in
            switch result {
            case .Success(let stats):
                let data = barChartMapper(stats)
                self.updateChart(self.detailChart, data: data, stats: stats)
                self.updateDescriptionLabel()
                break
            case .Failure(let err):
                switch err {
                case .CredentialsMissing, .LoginFaild(_):
                    self.performSegueWithIdentifier("to_login", sender: self)
                default:
                    print("what")
                }
            }
        }
    }
    
    func chartValueNothingSelected(chartView: ChartViewBase) {
        
    }
    
    func updateDescriptionLabel() {
        guard let idx = self.selectedIndexMainChart else {
            self.detailChartLabel.text = "Win rates as ..."
            return
        }
        let attrString = NSMutableAttributedString(string: "Win rates as ")
        let labelString = NSAttributedString(string: "\(self.yNames[idx])",
                                            attributes: [NSForegroundColorAttributeName: self.barColors[idx],
                                                NSFontAttributeName: UIFont.boldSystemFontOfSize(self.detailChartLabel.font.pointSize)])
        attrString.appendAttributedString(labelString)
        self.detailChartLabel.attributedText = attrString
    }
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {
        
    }
}

class CustomChartMarker: ChartMarker
{
    let stats: [Stats]!
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
    override func draw(context context: CGContext, point: CGPoint)
    {
        let font = UIFont.systemFontOfSize(UIFont.systemFontSize())
        let attrsDictionary = [NSFontAttributeName:font] as [String : AnyObject]
        let str = NSAttributedString(string: strVal, attributes: attrsDictionary)
        let rectSize = str.boundingRectWithSize(CGSize(width: 300, height: 20), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
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
        CGContextSetLineWidth(context, 1.0)
        CGContextSetStrokeColorWithColor(context, UIColor.blackColor().CGColor)
        CGContextSetFillColor(context, CGColorGetComponents(UIColor.whiteColor().CGColor))
        CGContextFillRect(context, rect)
        CGContextStrokeRect(context, rect)
        UIGraphicsPopContext()
        NSString(string: strVal).drawInRect(rect.offsetBy(dx: 3, dy: 2), withAttributes: attrsDictionary)
    }
    
    /// This method enables a custom ChartMarker to update it's content everytime the MarkerView is redrawn according to the data entry it points to.
    ///
    /// - parameter highlight: the highlight object contains information about the highlighted value such as it's dataset-index, the selected range or stack-index (only stacked bar entries).
    override func refreshContent(entry entry: ChartDataEntry, highlight: ChartHighlight)
    {
        let s = stats[entry.xIndex]
        let percentStr = String(format: "%.1f", entry.value)
        strVal = "\(percentStr)% (W: \(s.wins) / L: \(s.losses))"
    }
    
    override var size: CGSize {
        get { return markerSize }
    }
}