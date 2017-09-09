//
//  InterfaceController.swift
//  BikeShareWatch Extension
//
//  Created by Brad G. on 1/24/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation


class InterfaceController: WKInterfaceController
{
    var networks = UserDefaults.standard.networks ?? [BikeNetwork]()
    {
        didSet
        {
            self.table.setNumberOfRows(self.networks.count, withRowType: self.rowType)
            self.networks.enumerated().forEach
            {
                guard let controller = self.table.rowController(at: $0.0) as? StationRowObject else { return }
                controller.bikeNetwork = $0.1
            }
        }
    }
    @IBOutlet var table: WKInterfaceTable!
    @objc let rowType = "StationRow"
    
    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fetchNetworks), name: Notification.Name(Constants.DidUpdatedUserLocationNotification), object: nil)
        if let homeNetwork = UserDefaults.standard.homeNetwork
        {
            self.pushController(withName: "Stations", context: homeNetwork)
        }
        self.fetchNetworks()
    }
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any?
    {
        let network = self.networks[rowIndex]
        return network
    }
    
    override func didDeactivate()
    {
        NotificationCenter.default.removeObserver(self)
        super.didDeactivate()
    }
    
    @objc func fetchNetworks()
    {
        var networksClient = NetworksClient()
        networksClient.fetchNetworks
            { [weak self] response in
                DispatchQueue.main.async
                {
                    networksClient.invalidate()
                    switch response
                    {
                    case .error:
                        break
                    case .success(let networks):
                        self?.updateNetworksData(networks: networks)
                    }
                }
        }
    }
    
    func updateNetworksData(networks: [BikeNetwork])
    {
        guard ExtensionConstants.userManager.currentLocation != nil else
        {
            self.networks = networks
            UserDefaults.standard.setNetworks(networks: networks)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async
        { [weak self] in
            let sortedNetworks = networks.sorted { $0.location.distance < $1.location.distance }
            DispatchQueue.main.async
            {
                self?.networks = sortedNetworks
                UserDefaults.standard.setNetworks(networks: sortedNetworks)
            }
        }
    }

}

extension BikeNetworkLocation
{
    var userManager: UserManager
    {
        return ExtensionConstants.userManager
    }
    
    var distance: CLLocationDistance
    {
        guard let currentCoor = self.userManager.currentLocation else { return -1 }
        let stationLocation = CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
        let currentLocation = CLLocation(latitude: currentCoor.latitude, longitude: currentCoor.longitude)
        let distance = stationLocation.distance(from: currentLocation)
        return distance
    }
    
    var distanceDescription: String
    {
        let measurement = Measurement<UnitLength>(value: self.distance, unit: UnitLength.meters)
        let string = Constants.measurementFormatter.string(from: measurement)
        return "\(string) away"
    }
}
