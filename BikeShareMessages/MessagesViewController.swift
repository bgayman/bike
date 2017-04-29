//
//  MessagesViewController.swift
//  BikeShareMessages
//
//  Created by B Gay on 1/14/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let navigationController = UINavigationController(rootViewController: MessagesNetworkTableViewController())
        navigationController.navigationBar.barTintColor = UIColor.app_beige
        navigationController.view.frame = self.view.bounds
        self.addChildViewController(navigationController)
        self.view.addSubview(navigationController.view)
        navigationController.didMove(toParentViewController: self)
        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationController.view.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        navigationController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        navigationController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        navigationController.view.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor).isActive = true
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation)
    {
        guard let message = conversation.selectedMessage else { return }
        guard let url = message.url,
            let deeplink = Deeplink(url: url)
            else
        {
            return
        }
        self.handleDeeplink(deeplink: deeplink)
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation)
    {
        guard let url = message.url,
              let deeplink = Deeplink(url: url)
        else
        {
            return
        }
        self.handleDeeplink(deeplink: deeplink)
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle)
    {
        guard let navController = self.childViewControllers.first as? UINavigationController,
            let stationDetailViewController = navController.topViewController as? StationDetailViewController,
            presentationStyle == .compact
        else { return }
        stationDetailViewController.tableView.reloadData()
    }
    
    func createMessage(image: UIImage, bikeNetwork: BikeNetwork, bikeStation: BikeStation)
    {
        guard let conversation = self.activeConversation else { return }
        let session = conversation.selectedMessage?.session ?? MSSession()
        let message = MSMessage(session: session)
        message.url = URL(string: "\(Constants.WebSiteDomain)/network/\(bikeNetwork.id)/station/\(bikeStation.id)")
        let layout = MSMessageTemplateLayout()
        layout.image = image
        layout.caption = "\(bikeStation.name) - \(bikeStation.statusDisplayText)"
        message.layout = layout
        conversation.insert(message)
        { (error) in
            if let error = error
            {
                print(error)
            }
        }
    }
    
    func handleDeeplink(deeplink: Deeplink)
    {

        guard let navController = self.childViewControllers.first as? UINavigationController else { return }
        
        switch deeplink
        {
        case .network:
            if navController.presentedViewController != nil
            {
                navController.dismiss(animated: false)
            }
            guard let networkVC = navController.viewControllers.first as? MessagesNetworkTableViewController else { return }
            navController.popToRootViewController(animated: true)
            networkVC.handleDeeplink(deeplink)
        case .station(_, let stationID):
            if navController.presentedViewController != nil
            {
                navController.dismiss(animated: false)
            }
            if navController.viewControllers.count > 1
            {
                if let stationDetailVC = navController.topViewController as? StationDetailViewController
                {
                    guard stationDetailVC.station.id != stationID else
                    {
                        stationDetailVC.fetchStations()
                        return
                    }
                    _ = navController.popToViewController(navController.viewControllers[1], animated: false)
                    
                }
                guard let stationVC = navController.viewControllers[1] as? MessagesStationsTableViewController else
                {
                    guard let networkVC = navController.viewControllers.first as? MessagesNetworkTableViewController else { return }
                    networkVC.handleDeeplink(deeplink)
                    return
                }
                stationVC.handleDeeplink(deeplink)
            }
            else
            {
                guard let networkVC = navController.viewControllers.first as? MessagesNetworkTableViewController else { return }
                networkVC.handleDeeplink(deeplink)
            }
        case .systemInfo:
            break
        }
    }

}
