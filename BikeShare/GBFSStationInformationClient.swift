//
//  GBFSStationInformationClient.swift
//  BikeShare
//
//  Created by Brad G. on 2/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

struct GBFSStationsInformationClient
{
    //MARK: - Properties
    lazy var session: URLSession? =
    {
        return URLSession(configuration: URLSessionConfiguration.default)
    }()

    mutating func fetchGBFSStations(with href: URL, completion: @escaping (ClientResponse<[GBFSStationInformation]>) -> ())
    {
        let task = self.session?.dataTask(with: href)
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
            guard let info = json?["data"] as? JSONDictionary,
                let stationsJSON = info["stations"] as? [JSONDictionary]
                else
            {
                completion(.error(errorMessage: "Error: data malformed or corrupted"))
                return
            }
            let stations = stationsJSON.flatMap(GBFSStationInformation.init)
            completion(.success(response: stations))
        }
        task?.resume()
    }
    
    mutating func invalidate()
    {
        self.session?.invalidateAndCancel()
    }
}
