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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.chart.noDataText = "Loading data ..."
        // check login
        TrackOBot.instance.getByClassStats({
            (result) -> Void in
            switch result {
            case .Success(let stats):
                let data = stats.map { (d) -> BarChartDataEntry in
                    let val = Double(d.wins) / Double(d.wins + d.losses) * 100.0
                    return BarChartDataEntry(value: val, xIndex: HEROES.indexOf(d.hero)!)
                }
                let ds = BarChartDataSet(yVals: data, label: "Win %")
                ds.setColors(
                    [
                        UIColor(red: 167/255.0, green: 57.0/255.0, blue: 45.0/255.0, alpha: 1.0),
                        UIColor(red: 48/255.0, green: 60.0/255.0, blue: 108.0/255.0, alpha: 1.0),
                        UIColor(red: 37/255.0, green: 32.0/255.0, blue: 24.0/255.0, alpha: 1.0),
                        UIColor(red: 235/255.0, green: 154.0/255.0, blue: 68.0/255.0, alpha: 1.0),
                        UIColor(red: 35.0/255.0, green: 70.0/255.0, blue: 30.0/255.0, alpha: 1.0),
                        UIColor(red: 108/255.0, green: 68.0/255.0, blue: 30.0/255.0, alpha: 1.0),
                        UIColor(red: 88/255.0, green: 50.0/255.0, blue: 68.0/255.0, alpha: 1.0),
                        UIColor(red: 45/255.0, green: 83.0/255.0, blue: 125.0/255.0, alpha: 1.0),
                        UIColor(red: 250/255.0, green: 244/255.0, blue: 220.0/255.0, alpha: 1.0)
                    ], alpha: 0.95)
                let d = BarChartData(xVals: HEROES, dataSet: ds)

                self.chart.xAxis.labelRotationAngle = 90
                self.chart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.BottomInside
                self.chart.xAxis.setLabelsToSkip(0)
                self.chart.xAxis.spaceBetweenLabels = 0
                self.chart.legend.position = ChartLegend.ChartLegendPosition.AboveChartLeft
                self.chart.descriptionText = ""
                self.chart.leftAxis.labelCount = 5
                self.chart.leftAxis.forceLabelsEnabled = true
                self.chart.data = d
                self.chart.setNeedsDisplay()
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
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {
        
    }


    
}
