//
//  BikeStationGraphCollectionViewCell.swift
//  BikeShareTV
//
//  Created by B Gay on 9/23/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import Charts

// MARK: - BikeStationGraphCollectionViewCell
class BikeStationGraphCollectionViewCell: UICollectionViewCell
{
    
    // MARK: - Outlets
    @IBOutlet fileprivate weak var graphLabel: UILabel!
    @IBOutlet fileprivate weak var lineChartView: LineChartView!
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    fileprivate let labelAlpha: CGFloat = 0.70
    
    var stationStatuses: [BikeStationStatus]?
    {
        didSet
        {
            guard let stationStatuses = self.stationStatuses,
                  stationStatuses.isEmpty == false else { return }
            self.lineChartView.isHidden = false
            self.activityIndicator.stopAnimating()
            updateChartData()
        }
    }

    // MARK: - Setup
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        backgroundColor = .clear
        backgroundView = nil
        contentView.backgroundColor = .clear
        
        graphLabel.font = UIFont.systemFont(ofSize: 80.0, weight: .heavy)
        graphLabel.alpha = labelAlpha
        graphLabel.textColor = .black
        
        setupChartView()
    }
    
    private func setupChartView()
    {
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
        xAxis.axisLineWidth = 3.0
        
        let leftAxis = lineChartView.leftAxis
        leftAxis.labelPosition = .outsideChart
        leftAxis.labelFont = UIFont.app_font(forTextStyle: .caption1)
        leftAxis.labelTextColor = .gray
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawAxisLineEnabled = true
        leftAxis.axisMinimum = 0.0
        leftAxis.drawLabelsEnabled = true
        leftAxis.axisLineWidth = 3.0
        leftAxis.gridLineWidth = 3.0
        
        lineChartView.rightAxis.enabled = false
        lineChartView.isUserInteractionEnabled = false
    }
    
    private func updateChartData()
    {
        guard let stationStatues = self.stationStatuses else { return }
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
        set.lineWidth = 5.0
        set.highlightColor = UIColor.app_blue
        set.visible = true
        set.mode = .cubicBezier
        
        let chartData = LineChartData(dataSet: set)
        chartData.setValueTextColor(.white)
        chartData.setValueFont(UIFont.app_font(forTextStyle: .body))
        
        self.lineChartView.doubleTapToZoomEnabled = false
        self.lineChartView.data = chartData
        self.lineChartView.isHidden = false
    }
}
