//
//  SystemInfoTableViewContent.swift
//  BikeShare
//
//  Created by Brad G. on 2/12/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation
#if !os(macOS)
import UIKit
#if !os(tvOS)
import MessageUI
#endif
#else
import AppKit
#endif

enum SystemInfoTableViewContent
{
    static let dateFormatter: DateFormatter =
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter
    }()
    
    static let numberFormatter: NumberFormatter =
    {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        return numberFormatter
    }()
    
    case name(string: String)
    case shortName(string: String)
    case `operator`(string: String)
    case url(url: URL)
    case purchaseURL(url: URL)
    case stateDate(date: Date)
    case phoneNumber(string: String)
    case email(string: String)
    case licenseURL(url: URL)
    case timeZone(string: String)
    
    case pricingPlan(plan: GBFSSystemPricingPlan)
    case alert(alert: GBFSSystemAlert)
    
    static func content(for systemInfo: GBFSSystemInformation) -> [SystemInfoTableViewContent]
    {
        var tableViewContent:[SystemInfoTableViewContent] = [.name(string: systemInfo.name)]
        
        if let shortName = systemInfo.shortName
        {
            tableViewContent.append(.shortName(string: shortName))
        }
        if let `operator` = systemInfo.operator
        {
            tableViewContent.append(.operator(string: `operator`))
        }
        if let url = systemInfo.url
        {
            tableViewContent.append(.url(url: url))
        }
        if let purchaseURL = systemInfo.purchaseURL
        {
            tableViewContent.append(.purchaseURL(url: purchaseURL))
        }
        if let startDate = systemInfo.startDate
        {
            tableViewContent.append(.stateDate(date: startDate))
        }
        if let phoneNumber = systemInfo.phoneNumber
        {
            tableViewContent.append(.phoneNumber(string: phoneNumber))
        }
        if let email = systemInfo.email
        {
            tableViewContent.append(.email(string: email))
        }
        if let licenseURL = systemInfo.licenseURL
        {
            tableViewContent.append(.licenseURL(url: licenseURL))
        }
        tableViewContent.append(.timeZone(string: systemInfo.timeZone))
        return tableViewContent
    }
    
    static func content(for pricingPlan: GBFSSystemPricingPlan) -> [SystemInfoTableViewContent]
    {
        return [SystemInfoTableViewContent.pricingPlan(plan: pricingPlan)]
    }
    
    #if !os(macOS)
    func configure(cell: UITableViewCell)
    {
        cell.accessoryType = .none
        cell.detailTextLabel?.textColor = .gray
        cell.contentView.backgroundColor = .app_beige
        cell.backgroundColor = .app_beige
        switch self
        {
        case .name(let name):
            cell.textLabel?.text = "Name:"
            cell.detailTextLabel?.text = name
        case .shortName(let shortName):
            cell.textLabel?.text = "Short Name:"
            cell.detailTextLabel?.text = shortName
        case .operator(let op):
            cell.textLabel?.text = "Operator:"
            cell.detailTextLabel?.text = op
        case .url(let url):
            cell.textLabel?.text = "Website:"
            cell.detailTextLabel?.text = url.absoluteString
            if UIApplication.shared.canOpenURL(url)
            {
                cell.detailTextLabel?.textColor = UIColor.app_blue
                cell.accessoryType = .disclosureIndicator
            }
        case .purchaseURL(let url):
            cell.textLabel?.text = "Signup Website:"
            cell.detailTextLabel?.text = url.absoluteString
            if UIApplication.shared.canOpenURL(url)
            {
                cell.detailTextLabel?.textColor = UIColor.app_blue
                cell.accessoryType = .disclosureIndicator
            }
        case .stateDate(let date):
            cell.textLabel?.text = "Start Date:"
            cell.detailTextLabel?.text = SystemInfoTableViewContent.dateFormatter.string(from: date)
        case .phoneNumber(let phoneNumber):
            cell.textLabel?.text = "Phone Number:"
            cell.detailTextLabel?.text = phoneNumber
            if UIApplication.shared.canOpenURL(URL(string: "tel://")!)
            {
                cell.detailTextLabel?.textColor = UIColor.app_blue
                cell.accessoryType = .disclosureIndicator
            }
        case .email(let email):
            cell.textLabel?.text = "Email:"
            cell.detailTextLabel?.text = email
            #if os(iOS)
            if MFMailComposeViewController.canSendMail()
            {
                cell.detailTextLabel?.textColor = UIColor.app_blue
                cell.accessoryType = .disclosureIndicator
            }
            #endif
        case .licenseURL(let url):
            cell.textLabel?.text = "License Website:"
            cell.detailTextLabel?.text = url.absoluteString
            if UIApplication.shared.canOpenURL(url)
            {
                cell.detailTextLabel?.textColor = UIColor.app_blue
                cell.accessoryType = .disclosureIndicator
            }
        case .timeZone(let timeZone):
            cell.textLabel?.text = "Time Zone:"
            cell.detailTextLabel?.text = timeZone
        case .pricingPlan, .alert:
            break
        }
    }
    #endif
}

extension SystemInfoTableViewContent: Equatable, Hashable
{
    static func ==(lhs: SystemInfoTableViewContent, rhs: SystemInfoTableViewContent) -> Bool
    {
        switch (lhs, rhs)
        {
        case (.name(let name), .name(let otherName)):
            return name == otherName
        case (.shortName(let shortName), .shortName(let otherShortName)):
            return shortName == otherShortName
        case (.operator(let op), .operator(let otherOp)):
            return op == otherOp
        case (.url(let url), .url(let otherUrl)):
            return url == otherUrl
        case (.purchaseURL(let url), .purchaseURL(let otherURL)):
            return url == otherURL
        case (.stateDate(let date), .stateDate(let otherDate)):
            return date == otherDate
        case (.phoneNumber(let phoneNumber), .phoneNumber(let otherPhoneNumber)):
            return phoneNumber == otherPhoneNumber
        case (.email(let email), .email(let otherEmail)):
            return email == otherEmail
        case (.licenseURL(let url), .licenseURL(let otherURL)):
            return url == otherURL
        case (.timeZone(let timeZone), .timeZone(let otherTimeZone)):
            return timeZone == otherTimeZone
        case (.pricingPlan(let plan), .pricingPlan(let otherPlan)):
            return plan.planID == otherPlan.planID
        case (.alert(let alert), .alert(let otherAlert)):
            return alert.alertID == otherAlert.alertID
        default:
            return false
        }
    }
    
    var hashValue: Int
    {
        switch self
        {
        case .name(let name):
            return "name\(name)".hashValue
        case .shortName(let shortName):
            return "shortName\(shortName)".hashValue
        case .operator(let op):
            return "operator\(op)".hashValue
        case .url(let url):
            return "url\(url.absoluteString)".hashValue
        case .purchaseURL(let url):
            return "purchaseURL\(url.absoluteString)".hashValue
        case .stateDate(let date):
            return "date\(date)".hashValue
        case .phoneNumber(let phoneNumber):
            return "phoneNumber\(phoneNumber)".hashValue
        case .email(let email):
            return "email\(email)".hashValue
        case .licenseURL(let url):
            return "licenseURL\(url)".hashValue
        case .timeZone(let timeZone):
            return "timeZone\(timeZone)".hashValue
        case .pricingPlan(let plan):
            return "pricingPlan\(plan.planID)".hashValue
        case .alert(let alert):
            return "alert\(alert.alertID)".hashValue
        }
    }
}
