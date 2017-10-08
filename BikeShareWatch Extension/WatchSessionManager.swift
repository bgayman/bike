//
//  WatchSessionManager.swift
//  WatchConnectivityDemo
//
//  Created by Natasha Murashev on 9/3/15.
//  Copyright © 2015 NatashaTheRobot. All rights reserved.
//

import WatchConnectivity
#if os(iOS)
import UIKit
#endif

class WatchSessionManager: NSObject, WCSessionDelegate {
    
    @objc static let sharedManager = WatchSessionManager()
    private override init() {
        super.init()
    }
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        print(error?.localizedDescription ?? "NO ERROR")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    #endif
    
    @objc var validSession: WCSession? {
        
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        
        #if os(iOS)
            if let session = session, session.isPaired && session.isWatchAppInstalled
            {
                return session
            }
            return nil
        #elseif os(watchOS)
            return session
        #endif
    }
    
    @objc func startSession() {
        session?.delegate = self
        session?.activate()
    }
}

// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchSessionManager {
    
    // Sender
    @objc func updateApplicationContext(applicationContext: [String : AnyObject]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                print("ERROR: \(error)")
                throw error
            }
        }
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // handle receiving application context
        DispatchQueue.main.async
        {
            if let homeNetwork = applicationContext[Constants.HomeNetworkKey] as? JSONDictionary,
                  let bikeNetwork = BikeNetwork(json: homeNetwork)
            {
                UserDefaults.standard.setHomeNetwork(bikeNetwork)
            }
            else if let stations = applicationContext["stations"] as? [JSONDictionary]
            {
                UserDefaults.standard.setClosebyStations(with: stations)
            }
            else if let homeNetwork = UserDefaults.standard.homeNetwork,
                    let favedStations = applicationContext[homeNetwork.id] as? [JSONDictionary]
            {
                UserDefaults.standard.setFavoriteStations(for: homeNetwork, favorites: favedStations.flatMap(BikeStation.init))
            }
        }
    }
}

// MARK: User Info
// use when your app needs all the data
// FIFO queue
extension WatchSessionManager {
    
    // Sender
    @objc func transferUserInfo(userInfo: [String : AnyObject]) -> WCSessionUserInfoTransfer? {
        return validSession?.transferUserInfo(userInfo)
    }
    
    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        // implement this on the sender if you need to confirm that
        // the user info did in fact transfer
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        // handle receiving user info
        DispatchQueue.main.async {
            // make sure to put on the main queue to update UI!
        }
    }
    
}

// MARK: Transfer File
extension WatchSessionManager {
    
    // Sender
    @objc func transferFile(file: NSURL, metadata: [String : AnyObject]) -> WCSessionFileTransfer? {
        return validSession?.transferFile(file as URL, metadata: metadata)
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        // handle filed transfer completion
    }
    
    // Receiver
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        // handle receiving file
        DispatchQueue.main.async {
            // make sure to put on the main queue to update UI!
        }
    }
}


// MARK: Interactive Messaging
extension WatchSessionManager {
    
    // Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        if let session = validSession , session.isReachable {
            return session
        }
        return nil
    }
    
    // Sender
    @objc func sendMessage(message: [String : AnyObject],
                     replyHandler: (([String : Any]) -> Void)? = nil,
                     errorHandler: ((Error) -> Void)? = nil)
    {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    @objc func sendMessageData(data: Data,
                         replyHandler: ((Data) -> Void)? = nil,
                         errorHandler: ((Error) -> Void)? = nil)
    {
        validReachableSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // Receiver
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        #if os(iOS)
            self.fetchStations(completion: replyHandler)
        #endif
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        // handle receiving message data
        DispatchQueue.main.async {
            // make sure to put on the main queue to update UI!
        }
    }
}

#if os(iOS)

#endif
