//
//  UIHitPassView.swift
//  Spectral
//
//  Created by David Grigoryan on 9/22/16.
//  Copyright © 2016 Yantech. All rights reserved.
//

import UIKit

class UIHitPassView: UIView {

    
    var enablePass: Bool = true
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !enablePass {
            return super.hitTest(point, with: event)
        }
        
        let hitView = super.hitTest(point, with: event)
        if hitView == self {
            return nil
        }
        return hitView
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
