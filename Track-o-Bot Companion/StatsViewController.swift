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
    
    @IBOutlet weak var chart: BarChartView!
    @IBOutlet weak var deckChart: BarChartView!
    
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.chart.noDataText = "Loading data ..."
        self.deckChart.noDataText = "Loading data ..."

        TrackOBot.instance.getByClassStats({
            (result) -> Void in
            switch result {
            case .Success(let stats):
                let data = self.createHeroBarChartData(stats)
                self.updateChart(self.chart, data: data, stats: stats)
                break
            case .Failure(let err):
                switch err {
                case .CredentialsMissing, .LoginFaild(_):
                    self.performSegueWithIdentifier("to_login", sender: self)
                default:
                    print("what")
                }
            }
        })
        
        TrackOBot.instance.getByDeckStats({
            (result) -> Void in
            switch result {
            case .Success(let stats):
                let data = self.createDeckBarChartData(stats)
                self.updateChart(self.deckChart, data: data, stats: stats)
                self.deckChart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.BottomInside
                break
            case .Failure(let err):
                switch err {
                case .CredentialsMissing, .LoginFaild(_):
                    self.performSegueWithIdentifier("to_login", sender: self)
                default:
                    print("what")
                }
            }
        })
    }
    
    func createHeroBarChartData(stats: [ByClassStats]) -> BarChartData {
        let data = stats.map { (d) -> BarChartDataEntry in
            let sum = d.wins + d.losses
            guard sum > 0 else {
                return BarChartDataEntry(value: 0.0, xIndex: HEROES.indexOf(d.hero)!)
            }
            let val = Double(d.wins) / Double(sum) * 100.0
            return BarChartDataEntry(value: val, xIndex: HEROES.indexOf(d.hero)!)
        }
        let ds = BarChartDataSet(yVals: data, label: "Win %")
        ds.setColors(self.heroColors, alpha: 0.95)

        let d = BarChartData(xVals: HEROES, dataSet: ds)
        return d
    }

    func createDeckBarChartData(stats: [ByDeckStats]) -> BarChartData {
        let decks = stats.map { d in d.deck as String}
        let data = stats.map { (d) -> BarChartDataEntry in
            let sum = d.wins + d.losses
            guard sum > 0 else {
                return BarChartDataEntry(value: 0.0, xIndex: decks.indexOf(d.deck)!)
            }
            let val = Double(d.wins) / Double(sum) * 100.0
            return BarChartDataEntry(value: val, xIndex: decks.indexOf(d.deck)!)
        }
        let ds = BarChartDataSet(yVals: data, label: "Win %")
        ds.setColors(ChartColorTemplates.liberty(), alpha: 1.0)
        let d = BarChartData(xVals: decks, dataSet: ds)
        return d
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
            
            var offset = CGPoint(x: 0, y: 0)
            if let width = chart.viewPortHandler?.chartWidth {
                if (point.x + rectSize.width > width) {
                    offset = CGPoint(x: -1.0 * rectSize.width, y: 0)
                }
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
            strVal = "W: \(s.wins) / L: \(s.losses)"
        }
        
        override var size: CGSize {
            get { return markerSize }
        }
    }
    
    func updateChart(chart: BarLineChartViewBase, data: ChartData, stats: [Stats]) {
        chart.xAxis.labelRotationAngle = 90
        chart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.Bottom
        chart.xAxis.setLabelsToSkip(0)
        chart.xAxis.spaceBetweenLabels = 0
        //chart.xAxis.valueFormatter = CustomXAxisValueFormatter(stats: stats)
        
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
        chart.marker = CustomChartMarker(chart: chart, stats: stats)

        chart.data = data
        chart.setNeedsDisplay()
    }
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: ChartHighlight) {
        
    }
    
    func chartValueNothingSelected(chartView: ChartViewBase) {
        
    }
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {
        
    }
}

class CustomXAxisValueFormatter : ChartXAxisValueFormatter {
    
    let stats: [Stats]!
    
    init(stats: [Stats]) {
        self.stats = stats
    }
    
    @objc func stringForXValue(index: Int, original: String, viewPortHandler: ChartViewPortHandler) -> String {
        let s = stats[index]
        return original + "\(s.wins) wins, \(s.losses) losses"
    }
}
