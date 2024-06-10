//
//  PenShape.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics
import UIKit

public class MagicWandShape: PenShape {

    var magicWandImage: UIImage?
    public var drawSize: CGSize = CGSize.zero
    
    override public func render(in context: CGContext, onlyLast: Bool = false) {
        if let image = self.magicWandImage {
            context.saveGState()
            image.draw(in: CGRect(origin: CGPoint.zero, size: drawSize))
            context.restoreGState()
            return
        }
        
        super.render(in: context, onlyLast: onlyLast)
    }
}
