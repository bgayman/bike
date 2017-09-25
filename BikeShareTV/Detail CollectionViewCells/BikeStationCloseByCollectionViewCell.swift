//
//  BikeStationCloseByCollectionViewCell.swift
//  BikeShareTV
//
//  Created by B Gay on 9/23/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

// MARK: - BikeStationCloseByCollectionViewCell
class BikeStationCloseByCollectionViewCell: UICollectionViewCell
{
    // MARK: - Outlets
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var closebyLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    var network: BikeNetwork?
    {
        didSet
        {
            networkLabel.text = network?.name
        }
    }
    
    var closebyStations: [BikeStation]?
    {
        didSet
        {
            collectionView.reloadData()
        }
    }
    
    override var canBecomeFocused: Bool
    {
        return false
    }
    
    fileprivate let labelAlpha: CGFloat = 0.70
    
    // Lifecycle
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        collectionView.dataSource = self
        collectionView.contentInsetAdjustmentBehavior = .never
        
        backgroundColor = .clear
        backgroundView = nil
        contentView.backgroundColor = .clear
        
        networkLabel.alpha = labelAlpha
        networkLabel.textColor = .black
        networkLabel.font = UIFont.systemFont(ofSize: 80.0, weight: .heavy)
        
        closebyLabel.font = UIFont.systemFont(ofSize: 60.0, weight: .heavy)
        closebyLabel.alpha = labelAlpha
        closebyLabel.textColor = .black
        
        let nib = UINib(nibName: "\(BikeStationClosebyStationCollectionViewCell.self)", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "\(BikeStationClosebyStationCollectionViewCell.self)")
    }
}

// MARK: - Collection View
extension BikeStationCloseByCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return closebyStations?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "\(BikeStationClosebyStationCollectionViewCell.self)", for: indexPath) as! BikeStationClosebyStationCollectionViewCell
        cell.bikeStation = closebyStations?[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)
    {
        print(context.nextFocusedIndexPath ?? "")
    }
}
