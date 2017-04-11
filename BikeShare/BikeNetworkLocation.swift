//
//  BikeNetworkLocation.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation
import CoreLocation

struct BikeNetworkLocation
{
    let city: String
    let country: String
    let coordinates: CLLocationCoordinate2D
}

extension BikeNetworkLocation
{
    init?(json: JSONDictionary)
    {
        guard let city = json["city"] as? String,
            let country = json["country"] as? String,
            let latitude = json["latitude"] as? Double,
            let longitude = json["longitude"] as? Double
            else
        {
            return nil
        }
        self.city = city
        self.country = country
        self.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var jsonDict: JSONDictionary
    {
        return ["city": self.city,
                "country": self.country,
                "latitude": self.coordinates.latitude,
                "longitude": self.coordinates.longitude]
    }
}
