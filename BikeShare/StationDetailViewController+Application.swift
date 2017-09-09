//
//  StationDetailViewController+Application.swift
//  BikeShare
//
//  Created by Brad G. on 1/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import MapKit

extension StationDetailViewController
{
    override var previewActionItems: [UIPreviewActionItem]
    {
        let shareActionItem = UIPreviewAction(title: "Share", style: .default)
        { _, viewController in
            guard let viewController = viewController as? StationDetailViewController,
                let url = URL(string: "\(Constants.WebSiteDomain)/network/\(viewController.network.id)/station/\(viewController.station.id)")
                else { return }
            let activity = ActivityViewCustomActivity.stationFavoriteActivity(station: self.station, network: self.network)
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: [activity])
            UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
        }
        let mapsActionItem = UIPreviewAction(title: "Open in Maps", style: .default)
        { _, viewController in
            guard let viewController = viewController as? StationDetailViewController
                else { return }
            viewController.openMapBikeStationInMaps(MapBikeStation(bikeStation: viewController.station))
        }
        let favorite = UIPreviewAction(title: "☆", style: .default)
        { [unowned self] _, viewController in
            guard let viewController = viewController as? StationDetailViewController
                else { return }
            let station = viewController.station
            var favedStations = UserDefaults.bikeShareGroup.favoriteStations(for: self.network)
            favedStations.append(station)
            let jsonDicts = favedStations.map { $0.jsonDict }
            try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [self.network.id: jsonDicts as AnyObject])
            UserDefaults.bikeShareGroup.setFavoriteStations(for: self.network, favorites: favedStations)
        }
        let unfavorite = UIPreviewAction(title: "★", style: .default)
        { [unowned self] _, viewController in
            guard let viewController = viewController as? StationDetailViewController
                else { return }
            let station = viewController.station
            var favedStations = UserDefaults.bikeShareGroup.favoriteStations(for: self.network)
            let favedS = favedStations.filter { $0.id == station.id }.last
            guard let favedStation = favedS,
                let index = favedStations.index(of: favedStation) else { return }
            favedStations.remove(at: index)
            let jsonDicts = favedStations.map { $0.jsonDict }
            try? WatchSessionManager.sharedManager.updateApplicationContext(applicationContext: [self.network.id: jsonDicts as AnyObject])
            UserDefaults.bikeShareGroup.setFavoriteStations(for: self.network, favorites: favedStations)
        }
        
        return UserDefaults.bikeShareGroup.favoriteStations(for: self.network).contains(where: { $0.id == self.station.id }) ? [shareActionItem, mapsActionItem, unfavorite] : [shareActionItem, mapsActionItem, favorite]
    }
    
    //MARK: - QuickAction
    @objc func addQuickAction()
    {
        var quickActions = UIApplication.shared.shortcutItems ?? [UIApplicationShortcutItem]()
        for quickAction in quickActions
        {
            guard quickAction.localizedTitle != self.station.name else
            {
                return
            }
        }
        if quickActions.count >= 4
        {
            quickActions = Array(quickActions.dropFirst())
        }
        let shortcut = UIApplicationShortcutItem(type: "station", localizedTitle: self.station.name, localizedSubtitle: self.network.name, icon:UIApplicationShortcutIcon(templateImageName: "bicycle"), userInfo: ["deeplink": "bikeshare://network/\(self.network.id)/station/\(self.station.id)"])
        quickActions.append(shortcut)
        UIApplication.shared.shortcutItems = quickActions
    }
    
    @objc func setNetworkActivityIndicator(shown: Bool)
    {
        UIApplication.shared.isNetworkActivityIndicatorVisible = shown
    }
    
    @objc func setupNavigationBar()
    {
        if self.navigationController?.viewControllers.count ?? 0 == 1
        {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didPressDone))
            self.navigationItem.leftBarButtonItem = self.actionBarButton
        }
        else
        {
            self.navigationItem.rightBarButtonItem = self.actionBarButton
        }
    }
}
