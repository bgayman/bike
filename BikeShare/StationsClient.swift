//
//  StationsClient.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation

class StationsClient
{
    //MARK: - Constants
    struct Constants
    {
        static let BaseURL = "https://api.citybik.es"
        static let HistoryBaseURL = "https://bike-share.mybluemix.net/network/"
    }

    //MARK: - Properties
    lazy var session: URLSession? =
    {
        return URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    //MARK: - Networking
    func fetchStationStatuses(with networkID: String, stationID: String, completion: @escaping (ClientResponse<[BikeStationStatus]>) -> ())
    {
        let url = URL(string: "\(Constants.HistoryBaseURL)\(networkID)/station/\(stationID)/history/json")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        let task = self.session?.dataTask(with: request)
        { (data, _, error) in
            guard error == nil else
            {
                completion(.error(errorMessage: "Error: \(error!.localizedDescription)"))
                return
            }
            guard let data = data else
            {
                completion(.error(errorMessage: "Error: could not get data."))
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary else
            {
                completion(.error(errorMessage: "Error: data malformed or corrupted"))
                return
            }
            guard let dictionaries = json?["statuses"] as? [JSONDictionary]
            else
            {
                completion(.error(errorMessage: "Error: data malformed."))
                return
            }
            let stations = dictionaries.flatMap(BikeStationStatus.init)
            completion(.success(response: stations))
        }
        task?.resume()
    }
    
    func fetchStations(with bikeNetwork: BikeNetwork, fetchGBFSProperties: Bool = false, completion: @escaping (ClientResponse<[BikeStation]>) -> ())
    {
        let url = URL(string: "\(Constants.BaseURL)\(bikeNetwork.href)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = self.session?.dataTask(with: request)
        { (data, _, error) in
            guard error == nil else
            {
                completion(.error(errorMessage: "Error: \(error!.localizedDescription)"))
                return
            }
            guard let data = data else
            {
                completion(.error(errorMessage: "Error: could not get data."))
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary else
            {
                completion(.error(errorMessage: "Error: data malformed or corrupted"))
                return
            }
            guard let dictionary = json?["network"] as? JSONDictionary,
                let dictionaries = dictionary["stations"] as? [JSONDictionary]
                else
            {
                completion(.error(errorMessage: "Error: data malformed."))
                return
            }
            let stations = dictionaries.flatMap(BikeStation.init)
            if fetchGBFSProperties && bikeNetwork.gbfsHref != nil
            {
                self.fetchGBFSInfo(with: bikeNetwork, stations: stations, completion: completion)
            }
            else
            {
                if bikeNetwork.id.lowercased() == "bikerio"
                {
                    let filteredStations = stations.filter { $0.id != "af80c66aabefbffde2f0e7a1ed725ebf" }
                    completion(.success(response: filteredStations))
                }
                else
                {
                    completion(.success(response: stations))
                }
                
            }
            
        }
        task?.resume()
    }
    
    func fetchGBFSInfo(with bikeNetwork: BikeNetwork, stations: [BikeStation], completion: @escaping (ClientResponse<[BikeStation]>) -> ())
    {
        var gbfsFeedClient = GBFSFeedClient()
        gbfsFeedClient.fetchGBFFeeds(with: bikeNetwork.gbfsHref)
        { (response) in
            guard case .success(let feeds) = response else
            {
                DispatchQueue.main.async
                    {
                        completion(.success(response: stations))
                }
                return
            }
            gbfsFeedClient.invalidate()
            self.fetchStationInfo(with: feeds, stations: stations, completion: completion)
        }
    }
    
    func fetchStationInfo(with feeds: [GBFSFeed], stations: [BikeStation], completion: @escaping (ClientResponse<[BikeStation]>) -> ())
    {
        let stationFeed = feeds.filter { $0.type == .stationInformation }
        guard let stationInfoFeed = stationFeed.first else
        {
            DispatchQueue.main.async
                {
                    completion(.success(response: stations))
            }
            return
        }
        var gbfsStationInformationClient = GBFSStationsInformationClient()
        gbfsStationInformationClient.fetchGBFSStations(with: stationInfoFeed.url)
        { (response) in
            guard case .success(let stationsInformation) = response else
            {
                DispatchQueue.main.async
                    {
                        completion(.success(response: stations))
                }
                return
            }
            let stationsDict: [String: GBFSStationInformation] = stationsInformation.reduce([String: GBFSStationInformation]())
            { (result, stationInformation) in
                var result = result
                result[stationInformation.stationID] = stationInformation
                return result
            }
            self.fetchStationStatus(with: feeds, stationsDict: stationsDict, stations: stations, completion: completion)
            gbfsStationInformationClient.invalidate()
        }
    }
    
    func fetchStationStatus(with feeds: [GBFSFeed], stationsDict: [String: GBFSStationInformation], stations: [BikeStation], completion: @escaping (ClientResponse<[BikeStation]>) -> ())
    {
        var stationsDict = stationsDict
        let stationFeed = feeds.filter { $0.type == .stationStatus }
        guard let stationStatusFeed = stationFeed.first else
        {
            DispatchQueue.main.async
                {
                    completion(.success(response: stations))
            }
            return
        }
        var gbfsStationStatusClient = GBFSStationsStatusClient()
        gbfsStationStatusClient.fetchGBFSStationStatuses(with: stationStatusFeed.url)
        { (response) in
            DispatchQueue.main.async
                {
                    guard case .success(let stationsStatuses) = response else
                    {
                        completion(.success(response: stations))
                        return
                    }
                    for stationStatus in stationsStatuses
                    {
                        stationsDict[stationStatus.stationID]?.stationStatus = stationStatus
                    }
                    var newStationsDict = [String: GBFSStationInformation]()
                    for (_, value) in stationsDict
                    {
                        newStationsDict[value.name] = value
                    }
                    let newStations: [BikeStation] = stations.map
                    {
                        var station = $0
                        station.gbfsStationInformation = newStationsDict[station.name]
                        return station
                    }
                    completion(.success(response: newStations))
            }
            gbfsStationStatusClient.invalidate()
        }
    }
    
    //MARK: - Lifecycle
    func invalidate()
    {
        self.session?.invalidateAndCancel()
    }
}
