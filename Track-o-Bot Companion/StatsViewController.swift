//
//  SettingsViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 08.09.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
//

import UIKit
import Charts


class StatsViewController: TrackOBotViewController {
    
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

        TrackOBot.instance.getByClassStats({
            (result) -> Void in
            switch result {
            case .Success(let stats):
                let data = self.createHeroBarChartData(stats)
                self.updateChart(self.chart, data: data)
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
                self.updateChart(self.deckChart, data: data)
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
        let d = BarChartData(xVals: decks, dataSet: ds)
        return d
    }
    
    func updateChart(chart: BarLineChartViewBase, data: ChartData) {
        chart.xAxis.labelRotationAngle = 90
        chart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.Bottom
        chart.xAxis.setLabelsToSkip(0)
        chart.xAxis.spaceBetweenLabels = 2
        chart.legend.position = ChartLegend.ChartLegendPosition.AboveChartLeft
        chart.descriptionText = ""
        chart.rightAxis.enabled = false
        chart.leftAxis.customAxisMax = 100
        chart.leftAxis.customAxisMin = 0
        chart.leftAxis.labelCount = 5
        chart.leftAxis.forceLabelsEnabled = true
        chart.data = data
        chart.setNeedsDisplay()
    }
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {
        
    }


    
}
