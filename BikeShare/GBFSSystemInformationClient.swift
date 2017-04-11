//
//  GBFSSystemInformationClient.swift
//  BikeShare
//
//  Created by Brad G. on 2/11/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

struct GBFSSystemInformationClient
{
    //MARK: - Properties
    lazy var session: URLSession? =
    {
        return URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    mutating func fetchGBFSSystemInformation(with href: URL, completion: @escaping (ClientResponse<GBFSSystemInformation>) -> ())
    {
        let systemInfoTask = self.session?.dataTask(with: href)
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
                  let systemInfo = GBFSSystemInformation(json: info)
            else
            {
                completion(.error(errorMessage: "Error: data malformed or corrupted"))
                return
            }
            completion(.success(response: systemInfo))
        }
        systemInfoTask?.resume()
    }
    
    mutating func invalidate()
    {
        self.session?.invalidateAndCancel()
    }
}
