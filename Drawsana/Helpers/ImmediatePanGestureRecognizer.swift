//
//  ImmediatePanGestureRecognizer.swift
//  Drawsana
//
//  Created by Steve Landey on 8/14/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/**
 Replaces a tap gesture recognizer and a pan gesture recognizer with just one
 gesture recognizer.

 Lifecycle:
 * Touch begins, state -> .began (all other touches are completely ignored)
 * Touch moves, state -> .changed
 * Touch ends
   * If touch moved more than 10px away from the origin at some point, then
     `hasExceededTapThreshold` was set to `true`. Target may use this to
     distinguish a pan from a tap when the gesture has ended and act
     accordingly.

 This behavior is better than using a regular UIPanGestureRecognizer because
 that class ignores the first ~20px of the touch while it figures out if you
 "really" want to pan. This is a drawing program, so that's not good.
 */
public class ImmediatePanGestureRecognizer: UIGestureRecognizer {
    var tapThreshold: CGFloat = 10
    var secondThreshold: CGFloat = 40

  // If gesture ends and this value is `true`, then the user's finger moved
  // more than `tapThreshold` points during the gesture, i.e. it is not a tap.
    public var hasExceededTapThreshold = false
    public var hasExceededSecondThreshold = false
    public var hadSecondTouch = false

    private var startPoint: CGPoint = .zero
    private var lastLastPoint: CGPoint = .zero
    private var lastLastTime: CFTimeInterval = 0
    private var lastPoint: CGPoint = .zero
    private var lastTime: CFTimeInterval = 0
    private var trackedTouch: UITouch?

  var velocity: CGPoint? {
    guard let view = view, let trackedTouch = trackedTouch else { return nil }
    let delta = trackedTouch.location(in: view) - lastLastPoint
    let deltaT = CGFloat(lastTime - lastLastTime)
    return CGPoint(x: delta.x / deltaT , y: delta.y - deltaT)
  }

    override public func location(in view: UIView?) -> CGPoint {
    guard let view = view else {
      return lastPoint
    }
    return view.convert(lastPoint, to: view)
  }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    guard trackedTouch == nil, let firstTouch = touches.first, let view = view else { return }
    hadSecondTouch = touches.count > 1
    trackedTouch = firstTouch
    startPoint = firstTouch.location(in: view)
    lastPoint = startPoint
    lastTime = CFAbsoluteTimeGetCurrent()
    lastLastPoint = startPoint
    lastLastTime = lastTime
    state = .began
  }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    guard
      state == .began || state == .changed,
      let view = view,
      let trackedTouch = trackedTouch,
      touches.contains(trackedTouch) else
    {
      return
    }
    hadSecondTouch = hadSecondTouch || touches.count > 1
    lastLastTime = lastTime
    lastLastPoint = lastPoint
    lastTime = CFAbsoluteTimeGetCurrent()
    lastPoint = trackedTouch.location(in: view)
    if (lastPoint - startPoint).length >= tapThreshold {
      hasExceededTapThreshold = true
    }
    
    if (lastPoint - startPoint).length >= secondThreshold {
        hasExceededSecondThreshold = true
    }

    state = .changed
        
    if hadSecondTouch {
        self.isEnabled = false
        self.isEnabled = true
    }
        print("TOUCH \(hadSecondTouch) \(lastTime)")

  }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard
      state == .began || state == .changed,
      let trackedTouch = trackedTouch,
      touches.contains(trackedTouch) else
    {
      return
    }
    
    state = .ended

    DispatchQueue.main.async {
      self.reset()
    }
  }

    override public func reset() {
    super.reset()
    
    trackedTouch = nil
    hasExceededTapThreshold = false
    hasExceededSecondThreshold = false
    hadSecondTouch = false
  }
}
