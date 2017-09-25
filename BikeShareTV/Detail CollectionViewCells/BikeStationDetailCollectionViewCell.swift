//
//  BikeStationDetailCollectionViewCell.swift
//  BikeShareTV
//
//  Created by B Gay on 9/23/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit
import MapKit

// MARK: - BikeStationDetailCollectionViewCell
class BikeStationDetailCollectionViewCell: UICollectionViewCell
{
    // MARK: - Outlets
    @IBOutlet fileprivate weak var mapView: MKMapView!
    @IBOutlet fileprivate weak var overlayView: UIView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var stationLabel: UILabel!
    
    // MARK: - Properties
    fileprivate let labelAlpha: CGFloat = 0.90
    lazy var gradientLayer: CAGradientLayer =
    {
        let gradientLayer = CAGradientLayer()
        let firstColor = UIColor.app_brown.withAlphaComponent(0.05)
        let secondColor = UIColor.app_brown.withAlphaComponent(0.5)
        gradientLayer.colors = [firstColor.cgColor, secondColor.cgColor]
        return gradientLayer
    }()
    
    var bikeStation: BikeStation?
    {
        didSet
        {
            guard let bikeStation = self.bikeStation else { return }
            titleLabel.attributedText = bikeStation.statusAttributedString
            stationLabel.text = bikeStation.name
            if descriptionLabel.text?.isEmpty == true
            {
                descriptionLabel.text = BikeStationDescriptionGenerator.descriptionMessage(for: bikeStation)
            }
            
            mapView.removeAnnotations(mapView.annotations)
            let annotation = MapBikeStation(bikeStation: bikeStation)
            mapView.addAnnotation(annotation)
            mapView.showAnnotations([annotation], animated: true)
        }
    }
    
    override var frame: CGRect
    {
        didSet
        {
            gradientLayer.frame = bounds
        }
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        mapView.delegate = self
        
        backgroundColor = .clear
        backgroundView = nil
        contentView.backgroundColor = .clear
        
        titleLabel.alpha = labelAlpha
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 80.0, weight: .heavy)
        
        stationLabel.alpha = labelAlpha
        stationLabel.textColor = .black
        stationLabel.font = UIFont.systemFont(ofSize: 80.0, weight: .heavy)
        
        descriptionLabel.font = UIFont.systemFont(ofSize: 60.0, weight: .heavy)
        descriptionLabel.alpha = labelAlpha
        descriptionLabel.textColor = .black
        
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "marker")
        
        setupGradientLayer()
    }
    
    private func setupGradientLayer()
    {
        overlayView.layer.addSublayer(gradientLayer)
        gradientLayer.frame = bounds
    }
}

extension BikeStationDetailCollectionViewCell: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard let mapBikeStation = annotation as? MapBikeStation else { return nil }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "marker", for: annotation) as! MKMarkerAnnotationView
        view.markerTintColor = mapBikeStation.bikeStation.pinTintColor
        return view
    }
}
