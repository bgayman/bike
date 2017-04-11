//
//  UserDefaults+Application.swift
//  BikeShare
//
//  Created by B Gay on 12/27/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation
import CoreLocation

extension UserDefaults
{
    static let bikeShareGroup = UserDefaults(suiteName: Constants.AppGroupName)!
    
    var homeNetwork: BikeNetwork?
    {
        guard let json = self.object(forKey: Constants.HomeNetworkKey) as? JSONDictionary else { return nil }
        guard let bikeNetwork = BikeNetwork(json: json) else { return nil }
        return bikeNetwork
    }
    
    func setHomeNetwork(_ homeNetwork: BikeNetwork?)
    {
        guard let homeNetwork = homeNetwork else
        {
            self.removeObject(forKey: Constants.HomeNetworkKey)
            return
        }
        self.set(homeNetwork.jsonDict, forKey: Constants.HomeNetworkKey)
        NSUbiquitousKeyValueStore.default().set(homeNetwork.jsonDict, forKey: Constants.HomeNetworkKey)
    }
    
    func setLocation(_ location: CLLocationCoordinate2D)
    {
        self.set(location.latitude, forKey: Constants.LocationLatitudeKey)
        self.set(location.longitude, forKey: Constants.LocationLongitudeKey)
        NSUbiquitousKeyValueStore.default().set(location.latitude, forKey: Constants.LocationLatitudeKey)
        NSUbiquitousKeyValueStore.default().set(location.longitude, forKey: Constants.LocationLongitudeKey)
    }
    
    var location: CLLocationCoordinate2D?
    {
        let latitude = self.double(forKey: Constants.LocationLatitudeKey)
        let longitude = self.double(forKey: Constants.LocationLongitudeKey)
        guard latitude != 0.0 && longitude != 0.0 else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func setNetworks(networks: [BikeNetwork])
    {
        let jsonDictionaries = networks.map { $0.jsonDict }
        self.set(jsonDictionaries, forKey: Constants.NetworksKey)
        NSUbiquitousKeyValueStore.default().set(jsonDictionaries, forKey: Constants.NetworksKey)
    }
    
    var networks: [BikeNetwork]?
    {
        guard let networks = self.object(forKey: Constants.NetworksKey) as? [JSONDictionary] else { return nil }
        return networks.flatMap { BikeNetwork(json: $0) }
    }
}
