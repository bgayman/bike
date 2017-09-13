//
//  BikeNetwork.swift
//  BikeShare
//
//  Created by B Gay on 12/24/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import Foundation

struct BikeNetwork
{
    let company: [String]
    let href: String
    let id: String
    let location: BikeNetworkLocation
    let name: String
    let gbfsHref: URL?
    
    var locationDisplayName: String
    {
        return "\(self.location.city), \(self.location.country)"
    }
    
    var jsonDict: JSONDictionary
    {
        return ["company": self.company,
                "href": self.href,
                "id": self.id,
                "location": self.location.jsonDict,
                "name": self.name,
                "gbfs_href": self.gbfsHref?.absoluteString ?? ""]
    }
}

extension BikeNetwork
{
    init?(json: JSONDictionary)
    {
        guard let company = json["company"] as? [String],
            let href = json["href"] as? String,
            let id = json["id"] as? String,
            let locationDict = json["location"] as? JSONDictionary,
            let location = BikeNetworkLocation(json: locationDict),
            let name = json["name"] as? String
            else
        {
            return nil
        }
        self.company = company
        self.href = href
        self.id = id
        self.location = location
        self.name = name
        if let urlString = json["gbfs_href"] as? String,
           urlString.contains("https:"),
           let url = URL(string: urlString)
        {
            self.gbfsHref = url
        }
        else
        {
            self.gbfsHref = nil
        }
    }
}

extension BikeNetwork: Equatable
{
    static func ==(lhs: BikeNetwork, rhs: BikeNetwork) -> Bool
    {
        return lhs.id == rhs.id && lhs.href == rhs.href && lhs.locationDisplayName == rhs.locationDisplayName
    }
}

extension BikeNetwork: Hashable
{
    var hashValue: Int
    {
        return self.id.hashValue
    }
}
