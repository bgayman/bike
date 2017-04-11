//
//  AppDelegate.swift
//  BikeShareMac
//
//  Created by Brad G. on 1/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    let userManager = UserManager()
    
    func applicationWillFinishLaunching(_ notification: Notification)
    {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(self.handleURLEvent(event:with:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        let store = NSUbiquitousKeyValueStore.default()
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateKVStoreItems(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
    }

    func applicationWillTerminate(_ aNotification: Notification)
    {
        // Insert code here to tear down your application
    }

    func handleURLEvent(event: NSAppleEventDescriptor, with replyEvent: NSAppleEventDescriptor)
    {
        guard let windowController = NSApplication.shared().mainWindow?.windowController as? WindowController,
              let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString),
              let deeplink = Deeplink(url: url)
        else { return }
        windowController.handle(deeplink: deeplink)
    }
}

extension AppDelegate
{
    func updateKVStoreItems(notification: Notification)
    {
        let userInfo = notification.userInfo
        guard let reasonForChange = userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber else { return }
        let reason = reasonForChange.intValue
        if reason == NSUbiquitousKeyValueStoreServerChange || reason == NSUbiquitousKeyValueStoreInitialSyncChange
        {
            if let changedKeys = userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            {
                let store = NSUbiquitousKeyValueStore.default()
                let userDefaults = UserDefaults.standard
                for key in changedKeys
                {
                    let value = store.object(forKey: key)
                    userDefaults.set(value, forKey: key)
                }
            }
        }
    }
}

