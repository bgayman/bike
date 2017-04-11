//
//  NSTableView+Animations.swift
//  BikeShare
//
//  Created by Brad G. on 1/17/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import AppKit

extension NSTableView
{
    func animateUpdate<T: Hashable>(with oldDataSource: [T], newDataSource: [T])
    {
        let oldArray = oldDataSource
        let oldSet = Set(oldArray)
        let newArray = newDataSource
        let newSet = Set(newArray)
        
        let removed = oldSet.subtracting(newSet)
        let inserted = newSet.subtracting(oldSet)
        let updated = newSet.intersection(oldSet)
        
        let removedIndexes = removed.flatMap{ oldArray.index(of: $0) }
        let insertedIndexes = inserted.flatMap{ newArray.index(of: $0) }
        let updatedIndexes = updated.flatMap{ oldArray.index(of: $0) }
        
        self.beginUpdates()
        self.reloadData(forRowIndexes: IndexSet(updatedIndexes), columnIndexes: IndexSet([0]))
        self.removeRows(at: IndexSet(removedIndexes), withAnimation: .slideUp)
        self.insertRows(at: IndexSet(insertedIndexes), withAnimation: .slideDown)
        self.endUpdates()
    }
}
