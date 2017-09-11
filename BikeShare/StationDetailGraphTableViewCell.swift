//
//  StationDetailGraphTableViewCell.swift
//  BikeShare
//
//  Created by B Gay on 4/22/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import Charts


class StationDetailGraphTableViewCell: UITableViewCell
{
    struct Constants
    {
        static let LayoutMargin: CGFloat = 8.0
    }
    
    var stationStatuses: [BikeStationStatus]?
    {
        didSet
        {
            guard self.stationStatuses != nil else { return }
            self.activityIndicator.isHidden = true
            self.updateChartData()
        }
    }
    
    @objc lazy var lineChartView: LineChartView =
    {
        let lineChartView = LineChartView(frame: .zero)
        
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(lineChartView)
        lineChartView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        lineChartView.leadingAnchor.constraint(equalTo: self.contentView.readableContentGuide.leadingAnchor, constant: Constants.LayoutMargin).isActive = true
        lineChartView.trailingAnchor.constraint(equalTo: self.contentView.readableContentGuide.trailingAnchor).isActive = true
        lineChartView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        
        lineChartView.backgroundColor = .app_beige
        lineChartView.drawGridBackgroundEnabled = false
        lineChartView.legend.enabled = false
        lineChartView.legend.form = .line
        lineChartView.chartDescription?.enabled = true
        lineChartView.chartDescription?.text = "Free Bikes"
        lineChartView.chartDescription?.textColor = .gray
        lineChartView.chartDescription?.font = UIFont.app_font(forTextStyle: .caption1)
        lineChartView.pinchZoomEnabled = false
        
        let xAxis = lineChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.app_font(forTextStyle: .caption1)
        xAxis.labelTextColor = .gray
        xAxis.granularity = 3600.0 * 24
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.valueFormatter = DateValueFormatter()
        
        let leftAxis = lineChartView.leftAxis
        leftAxis.labelPosition = .outsideChart
        leftAxis.labelFont = UIFont.app_font(forTextStyle: .caption1)
        leftAxis.labelTextColor = .gray
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawAxisLineEnabled = true
        leftAxis.axisMinimum = 0.0
        leftAxis.drawLabelsEnabled = true
        
        lineChartView.rightAxis.enabled = false
        lineChartView.isUserInteractionEnabled = false
        lineChartView.animate(xAxisDuration: 0)
        return lineChartView
    }()
    
    @objc lazy var activityIndicator: UIActivityIndicatorView =
    {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        return activityIndicator
    }()
    
    private func updateChartData()
    {
        guard let stationStatues: [BikeStationStatus] = self.stationStatuses else { return }
        let sortedStatues = stationStatues.sorted { $0.timestamp < $1.timestamp }
        let data: [ChartDataEntry] = sortedStatues.map { ChartDataEntry(x: $0.timestamp.timeIntervalSince1970, y: Double($0.numberOfBikesAvailable)) }
        
        let set = LineChartDataSet(values: data, label: "Free Bikes")
        set.setColor(UIColor.app_blue)
        set.axisDependency = .left
        set.valueTextColor = UIColor.app_blue
        set.fillColor = UIColor.app_blue
        set.drawFilledEnabled = false
        set.drawCirclesEnabled = false
        set.drawCircleHoleEnabled = false
        set.drawValuesEnabled = false
        set.fillAlpha = 0.80
        set.lineWidth = 1.5
        set.highlightColor = UIColor.app_blue
        set.visible = true
        
        let chartData = LineChartData(dataSet: set)
        chartData.setValueTextColor(.white)
        chartData.setValueFont(UIFont.app_font(forTextStyle: .body))
        
        self.lineChartView.doubleTapToZoomEnabled = false
        self.lineChartView.data = chartData
        self.lineChartView.animate(xAxisDuration: 0.3)
    }
}
