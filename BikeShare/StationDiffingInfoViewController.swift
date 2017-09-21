//
//  StationDiffingInfoViewController.swift
//  BikeShare
//
//  Created by B Gay on 9/15/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import MapKit

// MARK: - StationDiffingInfoViewController
class StationDiffingInfoViewController: UIViewController
{
    // MARK: - Properties
    lazy var doneButton: UIBarButtonItem =
    {
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didPressDone))
        return doneButton
    }()
    
    lazy var gradientLayer: CAGradientLayer =
    {
        let gradientLayer = CAGradientLayer()
        let firstColor = UIColor.gray.withAlphaComponent(0.4)
        let secondColor = UIColor.gray.withAlphaComponent(0.9)
        gradientLayer.colors = [firstColor.cgColor, secondColor.cgColor]
        return gradientLayer
    }()
    
    lazy var emitter: CAEmitterLayer =
    {
        let emitter = Emitter.make(with: [#imageLiteral(resourceName: "icBlueOval"), #imageLiteral(resourceName: "icGreenOval"), #imageLiteral(resourceName: "icRedOval")])
        emitter.frame = self.view.bounds
        emitter.emitterSize = CGSize(width: self.view.bounds.width, height: 5.0)
        return emitter
    }()
    
    fileprivate let network: BikeNetwork
    fileprivate var bikeStations: [BikeStation]
    fileprivate var dismissTransition: SlideUpTransition?
    fileprivate let presentTransition = SlideUpTransition(isAppearing: true)
    
    // MARK: - Outlets
    @IBOutlet fileprivate weak var mapView: MKMapView!
    @IBOutlet fileprivate weak var overlayView: UIView!
    @IBOutlet fileprivate weak var heatMapDescriptionLabel: UILabel!
    @IBOutlet fileprivate weak var heatMapInstructionsLabel: UILabel!
    
    
    // MARK: - Lifecycle
    init(bikeNetwork: BikeNetwork, bikeStations: [BikeStation])
    {
        self.bikeStations = bikeStations
        self.network = bikeNetwork
        super.init(nibName: "\(StationDiffingInfoViewController.self)", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        styleViews()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        emitter.frame = overlayView.bounds
        emitter.emitterSize = CGSize(width: overlayView.bounds.width * 2.0, height: 5.0)
        gradientLayer.frame = overlayView.bounds
    }
    
    // MARK: - Setup
    private func styleViews()
    {
        title = "Heat Map"
        navigationItem.rightBarButtonItem = doneButton
        
        dismissTransition = SlideUpTransition(isAppearing: false, view: view, presentedVC: self)
        
        heatMapDescriptionLabel.font = UIFont.app_font(forTextStyle: .title3, weight: .bold)
        heatMapDescriptionLabel.textColor = .black

        heatMapInstructionsLabel.font = UIFont.app_font(forTextStyle: .title1, weight: .heavy)
        heatMapInstructionsLabel.textColor = .white
        
        let annotations = bikeStations.map(MapBikeStation.init)
        mapView.register(DotAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Dot")
        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: true)
        
        setupGradientLayer()
    }
    
    private func setupGradientLayer()
    {
        overlayView.layer.addSublayer(gradientLayer)
        overlayView.layer.addSublayer(emitter)

    }
    
    // MARK: - Action
    @objc
    private func didPressDone()
    {
        dismiss(animated: true)
    }

}

extension StationDiffingInfoViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Dot", for: annotation)
        return view
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension StationDiffingInfoViewController: UIViewControllerTransitioningDelegate
{
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return presentTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return SlideUpTransition(isAppearing: false)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return dismissTransition?.panGestureRecognizer?.state != .possible ? dismissTransition : nil
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return nil
    }
}
