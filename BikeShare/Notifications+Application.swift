//
//  Notifications+Application.swift
//  BikeShare
//
//  Created by B Gay on 10/3/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Foundation

extension Notification.Name
{
    static let BikeStationDidAddToFavorites = Notification.Name("BikeStationDidAddToFavorites")
}

extension NotificationCenter
{
    @objc func when(_ name: Notification.Name, perform block: @escaping (Notification) -> ())
    {
        self.addObserver(forName: name, object: nil, queue: .main, using: block)
    }
}
