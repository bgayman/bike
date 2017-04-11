//
//  UserManager.swift
//  BikeShare
//
//  Created by B Gay on 12/26/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation
import CoreLocation

class UserManager: NSObject
{
    var currentLocation: CLLocationCoordinate2D?
    let locationManager: CLLocationManager =
    {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 50.0
        return locationManager
    }()
    
    override init()
    {
        super.init()
        self.setupLocationManager()
    }
    
    func setupLocationManager()
    {
        locationManager.delegate = self
    }
    
    func getUserLocation()
    {
        switch CLLocationManager.authorizationStatus()
        {
        case .authorizedWhenInUse, .authorizedAlways:
            #if !(os(tvOS) || os(watchOS))
                self.locationManager.startUpdatingLocation()
            #else
                self.locationManager.requestLocation()
            #endif
        case .denied, .restricted:
            break
        case .notDetermined:
        #if !os(macOS)
            self.locationManager.requestWhenInUseAuthorization()
        #endif
        }
    }
    
    func stopUpdatingLocation()
    {
        switch CLLocationManager.authorizationStatus()
        {
        case .authorizedWhenInUse, .authorizedAlways:
            #if !(os(tvOS) || os(watchOS))
                self.locationManager.stopUpdatingLocation()
            #else
                break
            #endif
        case .denied, .restricted:
            break
        case .notDetermined:
            break
        }
    }
}

extension UserManager: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch status
        {
        case .authorizedAlways, .authorizedWhenInUse:
            #if !(os(tvOS) || os(watchOS))
                self.locationManager.startUpdatingLocation()
            #else
                self.locationManager.requestLocation()
            #endif
        case .denied, .notDetermined, .restricted:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        guard let location = locations.first else { return }
        self.currentLocation = location.coordinate
        #if os(tvOS) || os(macOS)
            UserDefaults.bikeShareGroup.setLocation(location.coordinate)
        #endif
        NotificationCenter.default.post(name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print(error.localizedDescription)
    }
}
