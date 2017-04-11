//
//  WidgetStationClient.swift
//  BikeShare
//
//  Created by Brad G. on 3/18/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation
import CoreLocation

class WidgetStationClient
{
    //MARK: - Constants
    struct Constants
    {
        static let BaseURL = "https://bike-share.mybluemix.net/stations/"
    }
    
    //MARK: - Properties
    lazy var session: URLSession? =
        {
            return URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    //MARK: - Networking
    func fetchStations(with bikeNetwork: BikeNetwork, completion: @escaping (ClientResponse<[BikeStation]>) -> ())
    {
        let url = URL(string: "\(Constants.BaseURL)\(bikeNetwork.id)/json")!
        let task = self.session?.dataTask(with: url)
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
            guard let dictionaries = json?["stations"] as? [JSONDictionary] else
            {
                completion(.error(errorMessage: "Error: data malformed."))
                return
            }
            let stations = dictionaries.flatMap
            { (json: JSONDictionary) -> BikeStation? in
            var station = BikeStation(json: json)
            guard let gbfsStationDict = json["gbfsStationInformation"] as? JSONDictionary else { return station }
            station?.gbfsStationInformation = GBFSStationInformation(json: gbfsStationDict)
            guard let gbfsStationStatusDict = gbfsStationDict["stationStatus"] as? JSONDictionary else { return station }
            station?.gbfsStationInformation?.stationStatus = GBFSStationStatus(json: gbfsStationStatusDict)
            return station
            }
            completion(.success(response: stations))
        }
        task?.resume()
    }
    
    //MARK: - Lifecycle
    func invalidate()
    {
        self.session?.invalidateAndCancel()
    }
}
