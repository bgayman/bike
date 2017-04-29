//
//  ServiceProvider.swift
//  BikeShareTopShelf
//
//  Created by Brad G. on 1/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation
import TVServices
import UIKit

class ServiceProvider: NSObject, TVTopShelfProvider
{
    
    var items = [TVContentItem]()
    
    override init()
    {
        super.init()
    }

    // MARK: - TVTopShelfProvider protocol

    var topShelfStyle: TVTopShelfContentStyle
    {
        // Return desired Top Shelf style.
        return .inset
    }

    var topShelfItems: [TVContentItem]
    {
        guard let location = UserDefaults.bikeShareGroup.location
        else
        {
            return [TVContentItem]()
        }
        let semaphore = DispatchSemaphore(value: 0)
        
        if let homeNetwork = UserDefaults.bikeShareGroup.homeNetwork
        {
            let stationsClient = StationsClient()
            stationsClient.fetchStations(with: homeNetwork)
            { [weak self] (response) in
                DispatchQueue.main.async
                {
                    guard case .success(let result) = response
                        else
                    {
                        semaphore.signal()
                        return
                    }
                    let stations = Array(result.prefix(8))
                    self?.items = stations.map
                    { (station) in
                        let item = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: station.statusDisplayText, container: nil)!)!
                        item.displayURL = URL(string: "bikeshare://network/\(homeNetwork.id)/station/\(station.id)")
                        item.title = station.name
                        item.imageShape = .HDTV
                        item.imageURL = self?.imageURL(for: station)
                        return item
                    }
                    stationsClient.invalidate()
                    semaphore.signal()
                }
            }
        }
        else
        {
            var closebyStationsClient = ClosebyStationsClient()
            closebyStationsClient.fetchStations(lat: location.latitude, long: location.longitude)
            { [weak self] (response) in
                DispatchQueue.main.async
                {
                    guard case .success(let result) = response
                        else
                    {
                        semaphore.signal()
                        return
                    }
                    let network = result.0
                    let stations = result.1
                    self?.items = stations.map
                    { (station) in
                        let item = TVContentItem(contentIdentifier: TVContentIdentifier(identifier: station.statusDisplayText, container: nil)!)!
                        item.displayURL = URL(string: "bikeshare://network/\(network.id)/station/\(station.id)")
                        item.title = station.name
                        item.imageShape = .HDTV
                        item.imageURL = self?.imageURL(for: station)
                        return item
                    }
                    closebyStationsClient.invalidate()
                    semaphore.signal()
                }
            }
        }
        
        let _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return items
    }
    
    func imageURL(for station: BikeStation) -> URL?
    {
        let topShelfView = TopShelfView(title: station.name, subtitle: station.statusDisplayText, pinColor: station.pinTintColor)
        topShelfView.layoutIfNeeded()
        topShelfView.pinView.setNeedsDisplay()
        guard let image = topShelfView.snapshot,
              let data = UIImagePNGRepresentation(image)
        else { return nil }
        return data.writePNG(to: "bike-share\(station.id)")
    }

}

extension UIView
{
    var snapshot: UIImage?
    {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        self.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}


extension Data
{
    func writePNG(to fileName: String) -> URL?
    {
        guard let docDirectory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
        let url = docDirectory.appendingPathComponent(fileName).appendingPathExtension("png")
        do
        {
            try self.write(to: url)
        }
        catch
        {
            print("error2 \(error) \(url.absoluteString)")
            return nil
        }
        return url
    }
}
