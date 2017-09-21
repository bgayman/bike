//
//  BikeNetworkTableViewCell.swift
//  BikeShare
//
//  Created by Brad G. on 9/10/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

class BikeNetworkTableViewCell: UITableViewCell
{
    // MARK: - Properties
    var bikeNetwork: BikeNetwork?
    {
        didSet
        {
            guard let bikeNetwork = self.bikeNetwork else { return }
            guard self.searchString == nil else
            {
                self.configureCell(searchString: self.searchString!)
                return
            }
            
            self.configureCell(bikeNetwork: bikeNetwork)
        }
    }
    
    @objc var searchString: String?
        {
        didSet
        {
            guard let searchString = self.searchString else { return }
            self.configureCell(searchString: searchString)
        }
    }
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var gbfsLabel: UILabel!
    
    // MARK: - Life cycle
    override func awakeFromNib()
    {
        super.awakeFromNib()
        titleLabel.font = UIFont.app_font(forTextStyle: .title2, weight: UIFont.Weight.semibold)
        subtitleLabel.font = UIFont.app_font(forTextStyle: .title1, weight: UIFont.Weight.light)
        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        
        gbfsLabel.font = UIFont.app_font(forTextStyle: .headline, weight: .heavy)
        gbfsLabel.textColor = .white
        gbfsLabel.layer.cornerRadius = 8.0
        gbfsLabel.layer.masksToBounds = true
        gbfsLabel.backgroundColor = UIColor.app_blue
    }
    
    // MARK: - Private
    private func configureCell(bikeNetwork: BikeNetwork)
    {
        self.titleLabel.text = bikeNetwork.name
        self.subtitleLabel.text = bikeNetwork.locationDisplayName
        gbfsLabel.isHidden = bikeNetwork.gbfsHref == nil
    }
    
    private func configureCell(searchString: String)
    {
        guard let bikeNetwork = self.bikeNetwork else { return }
        configureCell(bikeNetwork: bikeNetwork)
        let titleAttribString = NSMutableAttributedString(string: bikeNetwork.name, attributes: [NSAttributedStringKey.font: self.titleLabel.font])
        let subtitleAttribString = NSMutableAttributedString(string: bikeNetwork.locationDisplayName, attributes: [NSAttributedStringKey.font: self.subtitleLabel.font])
        
        self.titleLabel.attributedText = self.searchHightlighted(attribString: titleAttribString, searchString: searchString)
        self.subtitleLabel.attributedText = self.searchHightlighted(attribString: subtitleAttribString, searchString: searchString)
    }
    
    private func searchHightlighted(attribString: NSMutableAttributedString, searchString: String) -> NSAttributedString
    {
        let range = (attribString.string.lowercased() as NSString).range(of: searchString.lowercased())
        attribString.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.app_blue], range: range)
        return attribString
    }
}

