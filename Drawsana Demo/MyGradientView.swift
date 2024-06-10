import UIKit

@objc class MyGradientView: UIView {
    @IBInspectable var direction: Int = 1 {
        didSet {
            self.updateGradient()
        }
    }
    @IBInspectable var opacity: CGFloat = 0.4 {
        didSet {
            self.updateGradient()
        }
    }
    
    @IBInspectable var firstColor: UIColor = UIColor.clear {
        didSet {
            self.updateGradient()
        }
    }
    
    @IBInspectable var secondColor: UIColor = UIColor.black {
        didSet {
            self.updateGradient()
        }
    }

    var gradLayer: CAGradientLayer?
    var enablePass: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupGradient()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupGradient()
    }
    
    private func setupGradient() {
        gradLayer = CAGradientLayer()
        
        self.layer.insertSublayer(gradLayer!, at: 0)
        self.updateLayer()
    }
    
    private func updateLayer() {
        gradLayer?.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateLayer()
    }
    
    private func updateGradient() {
        let array = [firstColor.cgColor, secondColor.withAlphaComponent(self.opacity).cgColor]
        if direction > 0 {
            gradLayer?.colors = array
        } else {
            gradLayer?.colors = array.reversed()
        }
    }
    
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
}
