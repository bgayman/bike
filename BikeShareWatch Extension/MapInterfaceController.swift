//
//  MapInterfaceController.swift
//  BikeShare
//
//  Created by Brad G. on 1/29/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import WatchKit
import Foundation
import MapKit


class MapInterfaceController: WKInterfaceController
{

    @IBOutlet var map: WKInterfaceMap!
    var currentSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        guard let station = context as? BikeStation else { return }
        let color: WKInterfaceMapPinColor
        switch station.pinTintColor
        {
        case UIColor.red:
            color = .red
        case UIColor.orange:
            color = .purple
        case UIColor.app_green:
            color = .green
        case UIColor.green:
            color = .green
        default:
            color = .purple
        }
        self.setMapTo(coordinate: station.coordinates)
        self.map.addAnnotation(station.coordinates, with: color)
    }
    
    func setMapTo(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegionMake(coordinate, currentSpan)
        let newCenterPoint = MKMapPointForCoordinate(coordinate)
        
        self.map.setVisibleMapRect(MKMapRectMake(newCenterPoint.x, newCenterPoint.y, currentSpan.latitudeDelta, currentSpan.longitudeDelta))
        self.map.setRegion(region)
    }
}
