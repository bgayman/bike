import UIKit

extension UITableViewController
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
        
        let removedIndexes = removed.flatMap{ oldArray.index(of: $0) }.map{ IndexPath(row: $0, section: 0) }
        let insertedIndexes = inserted.flatMap{ newArray.index(of: $0) }.map{ IndexPath(row: $0, section: 0) }
        let updatedIndexes = updated.flatMap{ oldArray.index(of: $0) }.map{ IndexPath(row: $0, section: 0) }
        
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: updatedIndexes, with: .none)
        self.tableView.deleteRows(at: removedIndexes, with: .top)
        self.tableView.insertRows(at: insertedIndexes, with: .top)
        self.tableView.endUpdates()
    }
}
