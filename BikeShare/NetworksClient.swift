//
//  NetworkClient.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation

//MARK: - NetworksClient
struct NetworksClient
{
    //MARK: - Constants
    struct Constants
    {
        static let NetworksURL = URL(string: "https://api.citybik.es/v2/networks")!
    }
    
    //MARK: - Properties
    lazy var session: URLSession? =
    {
        return URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    //MARK: - Networking
    mutating func fetchNetworks(completion: @escaping (ClientResponse<[BikeNetwork]>) -> ())
    {
        let task = self.session?.dataTask(with: Constants.NetworksURL)
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
            guard let dictionaries = json?["networks"] as? [JSONDictionary] else
            {
                completion(.error(errorMessage: "Error: data malformed."))
                return
            }
            let networks = dictionaries.flatMap(BikeNetwork.init)
            completion(.success(response: networks))
        }
        task?.resume()
    }
    
    //MARK: - Lifecycle
    mutating func invalidate()
    {
        self.session?.invalidateAndCancel()
    }
}
