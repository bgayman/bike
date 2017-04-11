//
//  MapBikeNetwork.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation
import MapKit

/**
 *  Box class of BikeNetwork for MKAnnotation conformance
 */

class MapBikeNetwork: NSObject, MKAnnotation
{
    let bikeNetwork: BikeNetwork
    
    var title: String?
    {
        return self.bikeNetwork.name
    }
    
    var coordinate: CLLocationCoordinate2D
    {
        return self.bikeNetwork.location.coordinates
    }
    
    var subtitle: String?
    {
        return self.bikeNetwork.locationDisplayName
    }
    
    init(bikeNetwork: BikeNetwork)
    {
        self.bikeNetwork = bikeNetwork
        super.init()
    }
}
