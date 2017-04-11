//
//  StationDetailViewController+Messages.swift
//  BikeShare
//
//  Created by Brad G. on 1/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import MapKit

extension StationDetailViewController
{
    func addQuickAction(){}
    func setNetworkActivityIndicator(shown: Bool){}
    func setupNavigationBar()
    {
        self.tableView.allowsSelection = true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        switch indexPath.section
        {
        case 0:
            self.sendSnapshot(of: self.station)
        case 1:
            self.sendSnapshot(of: self.closebyStations[indexPath.row])
        default:
            break
        }
    }
    
    func sendSnapshot(of bikeStation: BikeStation)
    {
        self.mapView.showsUserLocation = false
        self.mapView.removeAnnotations(self.mapView.annotations)
        let annotation = MapBikeStation(bikeStation: bikeStation)
        self.mapView.showAnnotations([annotation], animated: true)
        DispatchQueue.main.delay(0.6)
        {[unowned self] in
            guard let image = self.mapView.snapshot,
                  let messagesViewController = self.navigationController?.parent as? MessagesViewController
            else { return }
            messagesViewController.createMessage(image: image, bikeNetwork: self.network, bikeStation: bikeStation)
        }
    }
}

extension UIView
{
    var snapshot: UIImage?
    {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 3)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
