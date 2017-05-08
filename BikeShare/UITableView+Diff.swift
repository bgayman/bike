//
//  UITableView+Diff.swift
//  BikeShare
//
//  Created by B Gay on 12/30/16.
//  Copyright © 2016 B Gay. All rights reserved.
//

import UIKit

extension UITableView
{
    func animateUpdate<T: Hashable>(with oldDataSource: [T], newDataSource: [T], section: Int = 0)
    {
        let oldArray = oldDataSource
        let oldSet = Set(oldArray)
        let newArray = newDataSource
        let newSet = Set(newArray)
        
        let removed = oldSet.subtracting(newSet)
        let inserted = newSet.subtracting(oldSet)
        let updated = newSet.intersection(oldSet)
        
        let removedIndexes = removed.flatMap{ oldArray.index(of: $0) }.map{ IndexPath(row: $0, section: section) }
        let insertedIndexes = inserted.flatMap{ newArray.index(of: $0) }.map{ IndexPath(row: $0, section: section) }
        let updatedIndexes = updated.flatMap{ oldArray.index(of: $0) }.map{ IndexPath(row: $0, section: section) }
        
        self.beginUpdates()
        self.reloadRows(at: updatedIndexes, with: .none)
        self.deleteRows(at: removedIndexes, with: .top)
        self.insertRows(at: insertedIndexes, with: .top)
        self.endUpdates()
    }
}
