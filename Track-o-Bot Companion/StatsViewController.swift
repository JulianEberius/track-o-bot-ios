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
                let d = BarChartData(xVals: HEROES, dataSet: ds)

                self.chart.xAxis.labelRotationAngle = 90
                self.chart.xAxis.labelPosition = ChartXAxis.XAxisLabelPosition.BottomInside
                self.chart.xAxis.setLabelsToSkip(0)
                self.chart.xAxis.spaceBetweenLabels = 0
                self.chart.legend.position = ChartLegend.ChartLegendPosition.AboveChartLeft
                self.chart.descriptionText = ""
                self.chart.data = d
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
