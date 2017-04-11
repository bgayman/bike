//
//  MapBikeStation.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation
import MapKit

/**
 *  Box class of BikeStation for MKAnnotation conformance
 */

class MapBikeStation: NSObject, MKAnnotation
{
    let bikeStation: BikeStation
    
    var title: String?
    {
        return self.bikeStation.name
    }
    
    var coordinate: CLLocationCoordinate2D
    {
        return self.bikeStation.coordinates
    }
    
    var subtitle: String?
    {
        return "\(self.bikeStation.statusDisplayText)"
    }
    
    var dateComponentText: String
    {
        return "\(self.bikeStation.dateComponentText)"
    }
    
    init(bikeStation: BikeStation)
    {
        self.bikeStation = bikeStation
        super.init()
    }
}

