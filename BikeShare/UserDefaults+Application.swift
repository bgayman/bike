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
    
    func isNetworkHomeNetwork(network: BikeNetwork) -> Bool
    {
        guard let homeNetwork = self.homeNetwork else { return false }
        return homeNetwork.id == network.id
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
        return networks.flatMap(BikeNetwork.init)
    }
    
    func favoriteStations(for bikeNetwork: BikeNetwork) -> [BikeStation]
    {
        guard let stations = self.object(forKey: bikeNetwork.id) as? [JSONDictionary] else { return [BikeStation]() }
        return stations.flatMap(BikeStation.init)
    }
    
    func removeStationFromFavorites(station: BikeStation, network: BikeNetwork)
    {
        var favedStations = self.favoriteStations(for: network)
        let favedS = favedStations.filter { $0.id == station.id }.last
        guard let favedStation = favedS,
            let index = favedStations.index(of: favedStation) else { return }
        favedStations.remove(at: index)
        self.setFavoriteStations(for: network, favorites: favedStations)
    }
    
    func addStationToFavorites(station: BikeStation, network: BikeNetwork)
    {
        var favedStations = self.favoriteStations(for: network)
        favedStations.append(station)
        self.setFavoriteStations(for: network, favorites: favedStations)
    }
    
    func isStationFavorited(station: BikeStation, network: BikeNetwork) -> Bool
    {
        return self.favoriteStations(for: network).contains(where: { $0.id == station.id })
    }
    
    func setFavoriteStations(for bikeNetwork: BikeNetwork, favorites: [BikeStation])
    {
        let jsonDictionaries = favorites.map { $0.jsonDict }
        self.set(jsonDictionaries, forKey: bikeNetwork.id)
        NSUbiquitousKeyValueStore.default().set(jsonDictionaries, forKey: bikeNetwork.id)
    }
    
    func setClosebyStations(with stations: [JSONDictionary])
    {
        self.set(stations, forKey: Constants.ClosebyStations)
    }
    
    var closebyStations: [BikeStation]
    {
        let stationsDict = self.array(forKey: Constants.ClosebyStations) as? [JSONDictionary]
        return stationsDict?.flatMap(BikeStation.init) ?? []
    }
    
    var hasPreviouslySelectedNetwork: Bool
    {
        return self.bool(forKey: Constants.PreviouslySelectedNetwork)
    }
    
    func setPreviouslySelectedNetwork(selected: Bool)
    {
        self.set(selected, forKey: Constants.PreviouslySelectedNetwork)
        NSUbiquitousKeyValueStore.default().set(selected, forKey: Constants.PreviouslySelectedNetwork)
    }
    
    var hasSeenWelcomeScreen: Bool
    {
        return self.bool(forKey: Constants.HasSeenWelcomeScreen)
    }
    
    func setHasSeenWelcomeScreen(seen: Bool)
    {
        self.set(seen, forKey: Constants.HasSeenWelcomeScreen)
        NSUbiquitousKeyValueStore.default().set(seen, forKey: Constants.HasSeenWelcomeScreen)
    }
}
