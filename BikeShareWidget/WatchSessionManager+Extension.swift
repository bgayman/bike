//
//  WatchSessionManager+Extension.swift
//  BikeShare
//
//  Created by B Gay on 5/13/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

extension WatchSessionManager
{
    var userManager: UserManager
    {
        return ExtensionConstants.userManager
    }
    
    func fetchStations(completion: @escaping ([String: Any]) -> ())
    {
        var closebyStationsClient = ClosebyStationsClient()
        guard let location = self.userManager.currentLocation else
        {
            completion([:])
            return
        }
        closebyStationsClient.fetchStations(lat: location.latitude, long: location.longitude, networkID: UserDefaults.bikeShareGroup.homeNetwork?.id)
        {(response) in
            DispatchQueue.main.async
            {
                guard case .success(let result) = response
                    else
                {
                    completion([:])
                    return
                }
                let network = result.0
                let stations = result.1
                closebyStationsClient.invalidate()
                completion(["network": network.jsonDict, "stations": stations.map { $0.jsonDict }])
            }
        }
    }
}
