//
//  ZoomDrawViewController.swift
//  Zoomerang
//
//  Created by David Grigoryan on 5/7/20.
//  Copyright © 2020 Arman Manukyan. All rights reserved.
//

import UIKit

class ZoomDrawViewController: UIViewController {
    @IBOutlet weak var scrollViewContrainerView: UIView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var bgImageView: UIImageView!
    
    @IBOutlet weak var drawingImageView: UIImageView!
    
    @IBOutlet weak var containerTop: NSLayoutConstraint!
    @IBOutlet weak var containerLeading: NSLayoutConstraint!
    @IBOutlet weak var containerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var centerViewHeightConstraint: NSLayoutConstraint!
    
    var zoom: CGFloat = 2.0
    private var penSize: CGFloat = 10
    
    var image: UIImage? = nil {
        didSet {
            self.bgImageView.image = self.image
        }
    }
    
    var offset: CGPoint = .zero {
        didSet {
            self.scrollView.contentOffset = CGPoint(x: offset.x - self.view.frame.size.width * 0.5,
                                                    y: offset.y - self.view.frame.size.height * 0.5)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        self.drawingImageView.alpha = 0.5
    }
    
    func setPenSize(penSize: CGFloat, scale: CGFloat) {
        let ns = min(2.0 + max(0, scale - 2.0), 4)
        let ps = min(50, penSize * ns)
        
        let s = ns * (ps / (penSize * ns))
           
        print("\(penSize) \(scale) \(ns) \(ps) \(s)")

        self.zoom = s
        self.penSize = ps
        self.updateCenterViewSize()
    }
        
    func updateCenterViewSize() {
        self.centerViewHeightConstraint.constant = self.penSize
        self.scrollView.zoomScale = self.zoom
        self.view.layoutIfNeeded()
    }
}

extension ZoomDrawViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.containerView
    }
}
