//
//  ExtensionDelegate.swift
//  BikeShareWatch Extension
//
//  Created by Brad G. on 1/24/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate
{
    @objc var watchConnectivityBackgroundTasks: [WKWatchConnectivityRefreshBackgroundTask] = []
    
    override init()
    {
        super.init()
        WatchSessionManager.sharedManager.startSession()
        let validSession = WatchSessionManager.sharedManager.validSession
        validSession?.addObserver(self, forKeyPath: "activationState", options: [], context: nil)
        validSession?.addObserver(self, forKeyPath: "hasContentPending", options: [], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        DispatchQueue.main.async
        {
            self.completeAllTasksIfReady()
        }
    }
    
    func applicationDidFinishLaunching()
    {
        WatchSessionManager.sharedManager.startSession()
    }

    func applicationDidBecomeActive()
    {
        ExtensionConstants.userManager.currentLocation = nil
        ExtensionConstants.userManager.getUserLocation()
    }

    func applicationWillResignActive()
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>)
    {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks
        {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
    
    @objc func handleWatchConnectivityBackgroundTask(_ backgroundTask: WKWatchConnectivityRefreshBackgroundTask)
    {
        self.watchConnectivityBackgroundTasks.append(backgroundTask)
    }
    
    @objc func completeAllTasksIfReady()
    {
        let validSession = WatchSessionManager.sharedManager.validSession
        if validSession?.activationState == .activated && validSession?.hasContentPending == false
        {
            watchConnectivityBackgroundTasks.forEach { $0.setTaskCompleted() }
            watchConnectivityBackgroundTasks.removeAll()
        }
    }

}
