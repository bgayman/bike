//
//  NetworkTableCell.swift
//  BikeShare
//
//  Created by Brad G. on 1/17/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import Cocoa

protocol NetworkTableCellDelegate: class
{
    func mouseDidEnter(cell: NetworkTableCell)
}

class NetworkTableCell: NSTableCellView
{
    
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var subtitleTextField: NSTextField!
    
    weak var delegate: NetworkTableCellDelegate?
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.addTrackingRect(self.bounds, owner: self, userData: nil, assumeInside: false)
    }
    
    override func mouseEntered(with event: NSEvent)
    {
        self.delegate?.mouseDidEnter(cell: self)
    }
}
