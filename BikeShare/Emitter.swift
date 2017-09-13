//
//  Emitter.swift
//  BikeShare
//
//  Created by B Gay on 9/12/17.
//  Copyright © 2017 B Gay. All rights reserved.
//

import UIKit

struct Emitter
{
    
    static func make(with images: [UIImage]) -> CAEmitterLayer
    {
        let emitter = CAEmitterLayer()
        emitter.emitterShape = kCAEmitterLayerLine
        emitter.emitterCells = generateEmitterCells(with: images)
        emitter.opacity = 0.4
        return emitter
    }
    
    static func generateEmitterCells(with images: [UIImage]) -> [CAEmitterCell]
    {
        let cells: [CAEmitterCell] = images.map
        { (image) in
            let cell = CAEmitterCell()
            cell.contents = image.cgImage
            cell.birthRate = 1
            cell.lifetime = 50
            cell.velocity = CGFloat(5.0)
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4.0
            cell.scale = 0.1
            cell.scaleRange = 0.1
            cell.alphaRange = 0.8
            cell.spinRange = 0.3
            cell.spin = 0.1
            return cell
        }
        return cells
    }
}

