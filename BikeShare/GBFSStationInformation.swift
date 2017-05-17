//
//  GBFSStationInformation.swift
//  BikeShare
//
//  Created by Brad G. on 2/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation
import CoreLocation

enum RentalMethod: String
{
    case key = "KEY"
    case creditCard = "CREDITCARD"
    case payPass = "PAYPASS"
    case applePay = "APPLEPAY"
    case transitCard = "TRANSITCARD"
    case accountNumber = "ACCOUNTNUMBER"
    case phone = "PHONE"
    
    var displayString: String
    {
        switch self
        {
        case .key:
            return "🔑"
        case .creditCard:
            return "💳"
        case .payPass:
            return "🛂"
        case .applePay:
            return ""
        case .transitCard:
            return "🚍"
        case .accountNumber:
            return "#"
        case .phone:
            return "📞"
        }
    }
    
    var meaningString: String
    {
        switch self
        {
        case .key:
            return "Key"
        case .creditCard:
            return "Credit Card"
        case .payPass:
            return "Pay Pass"
        case .applePay:
            return "Apple Pay"
        case .transitCard:
            return "Transit Card"
        case .accountNumber:
            return "Account Number"
        case .phone:
            return "Phone"
        }
    }
    
    static var all: [RentalMethod]
    {
        return [.key, .creditCard, .payPass, .applePay, .transitCard, .accountNumber, .phone]
    }
}

struct GBFSStationInformation
{
    let stationID: String
    let name: String
    let coordinates: CLLocationCoordinate2D
    let shortName: String?
    let address: String?
    let crossStreet: String?
    let regionID: String?
    let postCode: String?
    var rentalMethods: [RentalMethod]? = nil
    let capacity: Int?
    var stationStatus: GBFSStationStatus? = nil
    
    
}

extension GBFSStationInformation
{
    init?(json: JSONDictionary)
    {
        guard let stationID = json["station_id"] as? String,
              let name = json["name"] as? String,
              let lat = json["lat"] as? Double,
              let lon = json["lon"] as? Double else { return nil}
        self.stationID = stationID
        self.name = name
        self.coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        self.shortName = json["short_name"] as? String
        self.address = json["address"] as? String
        self.crossStreet = json["cross_street"] as? String
        self.regionID = json["region_id"] as? String
        self.postCode = json["post_code"] as? String
        if let rentalMethods = json["rental_methods"] as? [String]
        {
            self.rentalMethods = rentalMethods.flatMap { RentalMethod(rawValue: $0) }
        }
        self.capacity = json["capacity"] as? Int
    }
}
