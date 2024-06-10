
#if os(iOS)
import UIKit
typealias View = UIView
#else
import AppKit
typealias View = NSView
#endif

public extension View {
    // MARK: Frame
    public var viewOrigin: CGPoint {
        get { return self.frame.origin }
        set {
            self.frame.origin = newValue
        }
    }
    public var viewSize: CGSize {
        get { return self.frame.size }
        set {
            self.frame.size = newValue
        }
    }

    // MARK: Frame Origin
    public var x: CGFloat {
        get { return self.frame.origin.x }
        set {
            self.frame.origin.x = newValue
        }
    }
    public var y: CGFloat {
        get { return self.frame.origin.y }
        set {
            self.frame.origin.y = newValue
        }
    }

    // MARK: Frame Size
    public var width: CGFloat {
        get { return self.frame.size.width }
        set {
            self.frame.size.width = newValue
        }
    }
    public var height: CGFloat {
        get { return self.frame.size.height }
        set {
            self.frame.size.height = newValue
        }
    }

    // MARK: Frame Borders
    public var top: CGFloat {
        get { return self.y }
        set {
            self.y = newValue
        }
    }
    public var left: CGFloat {
        get { return self.x }
        set {
            self.x = newValue
        }
    }
    public var bottom: CGFloat {
        get { return self.frame.origin.y + self.frame.size.height }
        set {
            self.y = newValue - self.height
        }
    }
    public var right: CGFloat {
        get { return self.frame.origin.x + self.frame.size.width }
        set {
            self.x = newValue - self.width
        }
    }

    // MARK: Center Point
#if !os(iOS)
    public var center: CGPoint {
        get { return CGPoint(x: self.left + self.middleX, y: self.top + self.middleY) }
        set {
            self.left = newValue.x - self.middleX;
            self.top = newValue.y - self.middleY
        }
    }
#endif
    public var centerX: CGFloat {
        get { return self.center.x }
        set {
            self.center = CGPoint(x: newValue, y: self.center.y)
        }
    }
    public var centerY: CGFloat {
        get { return self.center.y }
        set {
            self.center = CGPoint(x: self.center.x, y: newValue)
        }
    }
    
    // MARK: Middle Point
    public var middlePoint: CGPoint {
        get { return CGPoint(x: self.middleX, y: self.middleY) }
    }
    public var middleX: CGFloat {
        get { return self.width / 2 }
    }
    public var middleY: CGFloat {
        get { return self.height / 2 }
    }
}
