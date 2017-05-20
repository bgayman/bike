//
//  ClosebyStationsClient.swift
//  BikeShare
//
//  Created by Brad G. on 1/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

struct ClosebyStationsClient
{
    //MARK: - Constants
    struct Constants
    {
        static let BaseURL = "https://bike-share.mybluemix.net"
    }
    
    //MARK: - Properties
    lazy var session: URLSession? =
    {
        return URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    //MARK: - Networking
    mutating func fetchStations(lat: Double, long: Double, networkID: String? = nil, completion: @escaping (ClientResponse<(BikeNetwork, [BikeStation])>) -> ())
    {
        let url: URL
        if let networkID = networkID
        {
            url = URL(string: "\(Constants.BaseURL)/json/network/\(networkID)/lat/\(lat)/long/\(long)")!
        }
        else
        {
            url = URL(string: "\(Constants.BaseURL)/json/lat/\(lat)/long/\(long)")!
        }
        
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
            do
            {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary,
                    let dictionary = json["network"] as? JSONDictionary,
                    let dictionaries = json["stations"] as? [JSONDictionary],
                    let network = BikeNetwork(json: dictionary)
                    else
                {
                    completion(.error(errorMessage: "Error: data malformed."))
                    return
                }
                let stations = dictionaries.flatMap(BikeStation.init)
                completion(.success(response: (network, stations)))

            }
            catch
            {
                completion(.error(errorMessage: "Error: data malformed or corrupted \(error)"))
                return
            }
            
        }
        task?.resume()
    }
    
    mutating func fetchStations(networkID: String, stationIDs: [String], completion: @escaping (ClientResponse<(BikeNetwork, [BikeStation])>) -> ())
    {
        let url: URL
        guard let stationsString = stationIDs.joined(separator: "|").addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else { return }
        url = URL(string: "\(Constants.BaseURL)/json/network/\(networkID)/stations/\(stationsString)")!
        
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
            do
            {
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary,
                    let dictionary = json["network"] as? JSONDictionary,
                    let dictionaries = json["stations"] as? [JSONDictionary],
                    let network = BikeNetwork(json: dictionary)
                    else
                {
                    completion(.error(errorMessage: "Error: data malformed."))
                    return
                }
                let stations = dictionaries.flatMap(BikeStation.init)
                completion(.success(response: (network, stations)))
                
            }
            catch
            {
                completion(.error(errorMessage: "Error: data malformed or corrupted \(error)"))
                return
            }
            
        }
        task?.resume()
    }
    
    //MARK: - Lifecycle
    mutating func invalidate()
    {
        self.session?.invalidateAndCancel()
    }
}
