//
//  PricingPlanTableViewCell.swift
//  BikeShare
//
//  Created by Brad G. on 2/12/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class PricingPlanTableViewCell: UITableViewCell
{
    @IBOutlet weak var planNameLabel: UILabel!
    @IBOutlet weak var planDetailLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var planPriceLabel: UILabel!
    @IBOutlet weak var planWebsiteLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var planPriceBottomConstraint: NSLayoutConstraint!
    
    var pricingPlan: GBFSSystemPricingPlan?
    {
        didSet
        {
            guard let pricingPlan = self.pricingPlan else { return }
            self.configureCell(with: pricingPlan)
        }
    }
    
    var alert: GBFSSystemAlert?
    {
        didSet
        {
            guard let alert = self.alert else { return }
            self.configureCell(with: alert)
        }
    }
    
    func configureCell(with plan: GBFSSystemPricingPlan)
    {
        self.contentView.backgroundColor = .clear
        if plan.description.isEmpty
        {
            self.planNameLabel.text = "Plan:"
            self.planDetailLabel.text = "\(plan.name.capitalized)"
            self.planDetailLabel.textColor = .gray
        }
        else
        {
            self.planNameLabel.text = "\(plan.name.capitalized):"
            self.planDetailLabel.text = plan.description
            self.planDetailLabel.textColor = .gray
        }
        
        self.priceLabel.text = "Price:"
        SystemInfoTableViewContent.numberFormatter.currencyCode = plan.currency
        self.planPriceLabel.text = "\(SystemInfoTableViewContent.numberFormatter.string(from: NSNumber(value: plan.price)) ?? "")"
        self.planPriceLabel.textColor = .gray
        
        if let url = plan.url
        {
            self.websiteLabel.text = "Plan Website:"
            self.planWebsiteLabel.text = url.absoluteString
            self.planWebsiteLabel.textColor = .gray
            if UIApplication.shared.canOpenURL(url)
            {
                self.planWebsiteLabel.textColor = UIColor.app_blue
                self.accessoryType = .disclosureIndicator
            }
        }
        else
        {
            self.websiteLabel.text = ""
            self.planWebsiteLabel.text = ""
            self.planPriceBottomConstraint.constant = 0
        }
        
    }
    
    func configureCell(with alert: GBFSSystemAlert)
    {
        #if !os(tvOS)
        self.contentView.backgroundColor = .app_beige
        self.backgroundColor = .app_beige
        #endif
        self.planNameLabel.text = "Alert:"
        self.planDetailLabel.text = "\(alert.type.displayText)"
        self.planDetailLabel.textColor = .gray
        self.planPriceBottomConstraint.constant = 4.0
        if let description = alert.description,
           !description.isEmpty
        {
            self.priceLabel.text = alert.summary
            let stationNames = alert.stations?.map { $0.name }
            let stationsString = stationNames?.joined(separator: "\n")
            self.planPriceLabel.text = stationsString == nil ? description : "\(description)\n\(stationsString ?? "")"
        }
        else
        {
            self.priceLabel.text = "Alert Summary:"
            let stationNames = alert.stations?.map { $0.name }
            let stationsString = stationNames?.joined(separator: "\n")
            self.planPriceLabel.text = stationsString == nil ? alert.summary : "\(alert.summary)\n\(stationsString ?? "")"
            self.planPriceLabel.textColor = .gray
        }
        
        if let url = alert.url
        {
            self.websiteLabel.text = "Alert Website:"
            self.planWebsiteLabel.text = url.absoluteString
            self.planWebsiteLabel.textColor = .gray
            self.planPriceBottomConstraint.constant = 4.0
            if UIApplication.shared.canOpenURL(url)
            {
                self.planWebsiteLabel.textColor = UIColor.app_blue
                self.accessoryType = .disclosureIndicator
            }
        }
        else
        {
            self.websiteLabel.text = ""
            self.planWebsiteLabel.text = ""
            self.planPriceBottomConstraint.constant = 0
        }
    }
    
}
