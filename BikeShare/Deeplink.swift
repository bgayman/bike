//
//  Deeplink.swift
//  BikeShare
//
//  Created by Brad G. on 1/7/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

//MARK: - Deeplinking

enum Deeplink
{
    case station(networkID: String, stationID: String)
    case network(id: String)
    case systemInfo(id: String)
    
    init?(url: URL)
    {
        guard let host = url.host else { return nil }
        switch host
        {
        case "network":
            if url.pathComponents.contains("station")
            {
                guard url.pathComponents.count > 1 else { return nil }
                let networkID = url.pathComponents[1]
                guard let stationID = url.pathComponents.last else { return nil }
                self = .station(networkID: networkID, stationID: stationID)
            }
            else
            {
                guard let networkID = url.pathComponents.first else {
                    return nil }
                self = .network(id: networkID)
            }
        case "bike-share.mybluemix.net":
            if url.pathComponents.contains("station")
            {
                guard url.pathComponents.count > 3 else { return nil }
                let networkID = url.pathComponents[2]
                guard let stationID = url.pathComponents.last else { return nil }
                self = .station(networkID: networkID, stationID: stationID)
            }
            else if url.pathComponents.contains("systemInfo")
            {
                guard let networkID = url.pathComponents.last else {
                    return nil }
                self = .systemInfo(id: networkID)
            }
            else
            {
                guard let networkID = url.pathComponents.last else {
                    return nil }
                self = .network(id: networkID)
            }
        default:
            return nil
        }
    }
}
