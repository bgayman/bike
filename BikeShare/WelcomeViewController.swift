//
//  WelcomeViewController.swift
//  BikeShare
//
//  Created by B Gay on 5/20/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

final class WelcomeViewController: UIViewController
{
    let gradientLayer: CAGradientLayer =
    {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.app_lightBlue.cgColor, UIColor.app_beige.cgColor]
        return gradientLayer
    }()
    
    lazy var stackView: UIStackView =
    {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        self.scrollView.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 8.0).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.view.readableContentGuide.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.view.readableContentGuide.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8.0 /*- self.continueButton.intrinsicContentSize.height*/).isActive = true
        //let bottomConstraint = stackView.bottomAnchor.constraint(equalTo: self.continueButton.topAnchor, constant: -8.0)
        //bottomConstraint.priority = 999
        //bottomConstraint.isActive = true
        stackView.spacing = 8.0
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    lazy var welcomeLabel: UILabel =
    {
        let welcomeLabel = UILabel()
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeLabel.text = "Welcome"
        welcomeLabel.font = UIFont.app_font(forTextStyle: .title1)
        welcomeLabel.textColor = UIColor.gray
        welcomeLabel.numberOfLines = 0
        welcomeLabel.textAlignment = .center
        welcomeLabel.lineBreakMode = .byWordWrapping
        return welcomeLabel
    }()
    
    lazy var waveImageView: UIImageView =
    {
        let waveImageView = UIImageView(image: #imageLiteral(resourceName: "waveBear"))
        waveImageView.translatesAutoresizingMaskIntoConstraints = false
        waveImageView.contentMode = .scaleAspectFit
        waveImageView.setContentCompressionResistancePriority(250, for: .vertical)
        return waveImageView
    }()
    
    lazy var descriptionLabel: UILabel =
    {
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "While not a bear necessity, Bike Bear works best if location services are enabled."
        descriptionLabel.font = UIFont.app_font(forTextStyle: .caption1)
        descriptionLabel.textColor = UIColor.gray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.setContentCompressionResistancePriority(1000, for: .vertical)
        return descriptionLabel
    }()
    
    lazy var seatedImageView: UIImageView =
    {
        let seatedImageView = UIImageView(image: #imageLiteral(resourceName: "seatedBear"))
        seatedImageView.translatesAutoresizingMaskIntoConstraints = false
        seatedImageView.contentMode = .scaleAspectFit
        return seatedImageView
    }()
    
    lazy var aboveDescriptionLabel: UILabel =
    {
        let aboveDescriptionLabel = UILabel()
        aboveDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        aboveDescriptionLabel.text = "So you can get from this…"
        aboveDescriptionLabel.font = UIFont.app_font(forTextStyle: .caption1)
        aboveDescriptionLabel.textColor = UIColor.gray
        aboveDescriptionLabel.numberOfLines = 0
        aboveDescriptionLabel.textAlignment = .center
        aboveDescriptionLabel.lineBreakMode = .byWordWrapping
        aboveDescriptionLabel.setContentCompressionResistancePriority(1000, for: .vertical)
        return aboveDescriptionLabel
    }()
    
    lazy var bikeImageView: UIImageView =
    {
        let bikeImageView = UIImageView(image: #imageLiteral(resourceName: "bikeBear"))
        bikeImageView.translatesAutoresizingMaskIntoConstraints = false
        bikeImageView.contentMode = .scaleAspectFit
        return bikeImageView
    }()
    
    lazy var subdescriptionLabel: UILabel =
    {
        let subdescriptionLabel = UILabel()
        subdescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        subdescriptionLabel.text = "to this."
        subdescriptionLabel.font = UIFont.app_font(forTextStyle: .caption1)
        subdescriptionLabel.textColor = UIColor.gray
        subdescriptionLabel.numberOfLines = 0
        subdescriptionLabel.textAlignment = .center
        subdescriptionLabel.lineBreakMode = .byWordWrapping
        subdescriptionLabel.setContentCompressionResistancePriority(1000, for: .vertical)
        return subdescriptionLabel
    }()
    
    lazy var continueButton: UIButton =
    {
        let continueButton = UIButton()
        continueButton.setTitle("Continue", for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = UIColor.app_blue
        continueButton.layer.cornerRadius = 5.0
        continueButton.layer.masksToBounds = true
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        //self.view.addSubview(continueButton)
        continueButton.widthAnchor.constraint(equalTo: self.stackView.widthAnchor, multiplier: 0.95)
        //continueButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -16.0).isActive = true
        //continueButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        #if !os(tvOS)
            continueButton.addTarget(self, action: #selector(self.didPressContinue), for: .touchUpInside)
        #else
            continueButton.addTarget(self, action: #selector(self.didPressContinue), for: .primaryActionTriggered)
        #endif
        continueButton.setContentHuggingPriority(1000, for: .vertical)
        continueButton.setContentCompressionResistancePriority(1000, for: .vertical)
        return continueButton
    }()
    
    lazy var scrollView: UIScrollView =
    {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        return scrollView
    }()
    
    var userManager: UserManager
    {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return UserManager() }
        return appDelegate.userManager
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        #if !os(tvOS)
        self.view.layer.addSublayer(self.gradientLayer)
        #else
        self.view.backgroundColor = .clear
        #endif
        self.stackView.addArrangedSubview(self.welcomeLabel)
        self.stackView.addArrangedSubview(self.waveImageView)
        self.stackView.addArrangedSubview(self.descriptionLabel)
        self.stackView.addArrangedSubview(self.seatedImageView)
        self.stackView.addArrangedSubview(self.aboveDescriptionLabel)
        self.stackView.addArrangedSubview(self.bikeImageView)
        self.stackView.addArrangedSubview(self.subdescriptionLabel)
        self.stackView.addArrangedSubview(self.continueButton)
        self.continueButton.isHidden = false
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        self.gradientLayer.frame = self.view.bounds
    }
    
    func didPressContinue()
    {
        UserDefaults.bikeShareGroup.setHasSeenWelcomeScreen(seen: true)
        self.userManager.getUserLocation()
        self.dismiss(animated: true)
    }
}

