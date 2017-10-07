//
//  FavoritesDropView.swift
//  BikeShare
//
//  Created by B Gay on 10/7/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class FavoritesDropView: UIView
{
    
    // MARK: - Properties
    static  let cornerRadius: CGFloat = 20.0
    private static let spacing: CGFloat = 2.0
    private static let titleText = "★"
    private static let descriptionText = "Drop here to favorite."
    
    static var height: CGFloat
    {
        let label = UILabel()
        label.text = FavoritesDropView.titleText
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        let titleHeight = label.sizeThatFits(CGSize(width: 320.0, height: CGFloat.greatestFiniteMagnitude)).height
        label.text = FavoritesDropView.descriptionText
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        let descriptionHeight = label.sizeThatFits(CGSize(width: 320.0, height: CGFloat.greatestFiniteMagnitude)).height
        
        return FavoritesDropView.cornerRadius * 2 + titleHeight + descriptionHeight + 4 * FavoritesDropView.spacing
    }
    
    override var intrinsicContentSize: CGSize
    {
        return CGSize(width: bounds.width, height: FavoritesDropView.height)
    }
    
    private lazy var titleLabel: UILabel =
    {
        let titleLabel  = UILabel()
        titleLabel.text = FavoritesDropView.titleText
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.textColor = .app_blue
        titleLabel.textAlignment = .center
        titleLabel.heightAnchor.constraint(lessThanOrEqualToConstant: 60.0)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        
        return titleLabel
    }()
    
    private lazy var descriptionLabel: UILabel =
    {
        let descriptionLabel  = UILabel()
        descriptionLabel.text = FavoritesDropView.descriptionText
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.textColor = .lightGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .vertical)
        
        return descriptionLabel
    }()
    
    private lazy var stackView: UIStackView =
    {
        let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.descriptionLabel])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = FavoritesDropView.spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: FavoritesDropView.cornerRadius).isActive = true
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -FavoritesDropView.cornerRadius - FavoritesDropView.spacing * 3.0).isActive = true
        
        return stackView
    }()
    
    private lazy var visualEffectView: UIVisualEffectView =
    {
        let visualEffectView = UIVisualEffectView(effect: nil)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(visualEffectView)
        visualEffectView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        visualEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        visualEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        return visualEffectView
    }()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit()
    {
        backgroundColor = .clear
        isOpaque = false
        visualEffectView.isHidden = false
        stackView.alpha = 0.0
        layer.cornerRadius = FavoritesDropView.cornerRadius
        layer.masksToBounds = true
    }
    
    func showDropView()
    {
        let effect = UIBlurEffect(style: .light)
        UIView.animate(withDuration: 0.4)
        { [unowned self] in
            self.visualEffectView.effect = effect
            self.stackView.alpha = 1.0
        }
    }
    
    func hideDropView()
    {
        UIView.animate(withDuration: 0.2, animations:
        { [unowned self] in
            self.visualEffectView.effect = nil
            self.stackView.alpha = 0.0
        })
    }
}

