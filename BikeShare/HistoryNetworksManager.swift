//
//  HistoryNetworksManager.swift
//  BikeShare
//
//  Created by B Gay on 4/22/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

class HistoryNetworksManager: NSObject
{
    var historyNetworks = [String]()
    static let shared = HistoryNetworksManager()
    
    func getHistoryNetworks()
    {
        var networkClient = NetworksClient()
        networkClient.fetchHistoryNetworks
        { (response) in
            switch response
            {
            case .error:
                break
            case .success(let networks):
                self.historyNetworks = networks
            }
            networkClient.invalidate()
        }
    }
}
