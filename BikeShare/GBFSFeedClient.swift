//
//  GBFSFeedClient.swift
//  BikeShare
//
//  Created by Brad G. on 2/12/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

struct GBFSFeedClient
{
    //MARK: - Properties
    lazy var session: URLSession? =
    {
        return URLSession(configuration: URLSessionConfiguration.default)
    }()
    
    mutating func fetchGBFFeeds(with href: URL?, completion: @escaping (ClientResponse<[GBFSFeed]>) -> ())
    {
        guard let href = href else
        {
            completion(.error(errorMessage: "No url"))
            return
        }
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
                let en = info["en"] as? JSONDictionary,
                let feedsJSON = en["feeds"] as? [JSONDictionary]
                else
            {
                completion(.error(errorMessage: "Error: data malformed or corrupted"))
                return
            }
            let feeds = feedsJSON.flatMap(GBFSFeed.init)
            completion(.success(response: feeds))
        }
        task?.resume()
    }
    
    mutating func invalidate()
    {
        self.session?.invalidateAndCancel()
    }
}
