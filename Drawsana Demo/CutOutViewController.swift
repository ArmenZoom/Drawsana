import Foundation
import UIKit
import Drawsana
import QuickLook

protocol CutOutViewControllerDelegate: class {
    func didCropSticker(image: UIImage)
}
enum CutOutViewSelectedAction: Int {
    case move = -1
    case erase = 0
    case draw = 1
    case magic = 2
    case area = 3
}

class CutOutViewController: UIViewController {
    
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var imageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageLeftContraint: NSLayoutConstraint!
    @IBOutlet weak var imageRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsView: UIHitPassView!
    
    @IBOutlet weak var hintLabel: UILabel!
    
    @IBOutlet weak var zoomContainerViewLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var zoomImageContainer: UIView!
    
    var zoomImageVC: ZoomDrawViewController?
    var zoomImageScale: CGFloat {
        return self.zoomImageVC?.zoom ?? 1.0
    }

    
    var selectedAction: CutOutViewSelectedAction = .area {
        didSet {
            self.scrollView?.isScrollEnabled = self.selectedAction == .move
            self.drawingView.isUserInteractionEnabled = self.selectedAction != .move
        }
    }
    var savedImageURL: URL {
      return FileManager.default.temporaryDirectory.appendingPathComponent("drawsana_demo").appendingPathExtension("jpg")
    }
    
    weak var delegate: CutOutViewControllerDelegate? = nil

    var image: UIImage! = nil {
        didSet {
            let aspect = self.image.size.height / self.image.size.width
            self.backgroundImageView.image = self.image
            self.zoomImageVC?.image = self.image

            var width  = min(self.image.size.width, self.view.frame.size.width)
            let height = min(aspect * width, self.view.frame.size.height)
            
            width = min(width, height/aspect)
            self.imageHeightConstraint.constant = height
            self.imageWidthConstraint.constant = width
            self.imageTopConstraint.constant = (self.view.height - height) / 2.0
            
            self.zoomImageVC?.containerWidthConstraint.constant  = width
            self.zoomImageVC?.containerHeightConstraint.constant  = height
            self.zoomImageVC?.view.layoutIfNeeded()
            
            self.view.layoutIfNeeded()
            self.drawingView.frame = self.backgroundImageView.frame
            self.drawingView.addImage(image: UIImage(named: "img")!, rect: CGRect(x: 150, y: 50, width: 120, height: 120))
            self.setupDraw()
            self.fetchZoomViews(scrollView: self.scrollView)
        }
    }
    
    var hint: String?
       
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var penHandle: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var penButton: UIButton!
    @IBOutlet weak var magicButton: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var zoomButton: UIButton!
    
    var tutorialCurrentStep: Int = -1
    
    lazy var drawingView: DrawsanaView = {
       return DrawsanaView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    }()
    
    lazy var tools: [DrawingTool] = {
        let tool1 = PenTool()
        let tool2 = EraserTool()
        let tool3 = MagicWandTool()
        let tool4 = RectTool()
        return [tool1, tool2, tool3, tool4]
    }()
    
    var magicWandTool: MagicWandTool? {
        return tools[2] as? MagicWandTool
    }
    
    func setupDraw() {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.drawingView.alpha = 0.5
        self.containerView.addSubview(drawingView)
        self.drawingView.delegate = self
        self.drawingView.operationStack.delegate = self
        self.drawingView.scrollViewPinchGesture = self.scrollView.pinchGestureRecognizer
        self.drawingView.scrollViewPanGesture = self.scrollView.panGestureRecognizer
        
        self.drawingView.userSettings.strokeColor = UIColor.red
        self.drawingView.userSettings.fillColor = UIColor.red
        self.drawingView.userSettings.strokeWidth = 10

        self.zoomImageContainer.layer.cornerRadius = zoomImageContainer.frame.size.width * 0.5
        self.zoomImageContainer.layer.borderColor = UIColor.white.cgColor
        self.zoomImageContainer.layer.borderWidth = 2
        self.zoomImageContainer.layer.masksToBounds = true
        
        
        self.updateButtons()
        self.applyUndoViewState()
        scrollView.delegate = self
        if self.selectedAction != .move {
            drawingView.set(tool: tools[self.selectedAction.rawValue])
        }
        
        if let hint = self.hint {
            self.hintLabel.text = hint
        } else {
            self.hintLabel.isHidden = true
        }
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startFadeAnimation()
        self.showTutorialIfNeeded(step: 0)
        self.fetchZoomViews(scrollView: self.scrollView)
        
        self.image = UIImage(named: "nkar")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopFadeAnimation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @objc func applicationDidBecomeActive() {
        self.drawingView.resetGesture()
    }
    
    @IBAction func didPressDone(_ sender: Any) {
        
    }
    @IBAction func didPressCancel(_ sender: Any) {
    }
    
    @IBAction func didPressRedo(_ sender: Any) {
        drawingView.operationStack.redo()
    }
    
    @IBAction func didPressUndo(_ sender: Any) {
        drawingView.operationStack.undo()
    }
    
    @IBAction func didPressErase(_ sender: Any) {
        if selectedAction == .erase {
            self.selectedAction = .move
        } else {
            selectedAction = .erase
            drawingView.set(tool: tools[1])
        }

        self.updateButtons()
    }
    
    @IBAction func didPressMove(_ sender: Any) {

        if self.scrollView.zoomScale == 1.0 {
            self.scrollView.setZoomScale(2.0, animated: true)
        } else {
            self.scrollView.setZoomScale(1.0, animated: true)
        }
        
    }
    
    @IBAction func didPressClean(_ sender: Any) {
        drawingView.operationStack.redo()
    }
    
    
    @IBAction func didPressMagic(_ sender: Any)  {
        if selectedAction == .magic {
            self.selectedAction = .move
        } else {
            selectedAction = .magic
            drawingView.set(tool: tools[2])
        }
        self.updateButtons()
    }
    
    @IBAction func didPressPen(_ sender: Any) {
        if selectedAction == .draw {
            self.selectedAction = .move
        } else {
            selectedAction = .draw
            drawingView.set(tool: tools[0])
        }
        self.updateButtons()
    }
    
    @IBAction func sliderDidChange(_ sender: Any) {
        let size = CGFloat(slider.value)
        penHandle.frame = CGRect(x: 0, y: 0, width: size, height: size)
        penHandle.center = self.view.center
        penHandle.layer.cornerRadius = size * 0.5
        penHandle.alpha = 1.0
        self.fetchPenSize()
    }
    @IBAction func sliderDidFinish(_ sender: Any) {
        penHandle.alpha = 0.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "ZoomVC" {
        if let childVC = segue.destination as? ZoomDrawViewController {
          //Some property on ChildVC that needs to be set
            self.zoomImageVC = childVC
        }
      }
    }

        
    /// Update button states to reflect undo stack
    private func applyUndoViewState() {
        undoButton.isEnabled = drawingView.operationStack.canUndo
        redoButton.isEnabled = drawingView.operationStack.canRedo
        doneButton.isEnabled = drawingView.operationStack.canUndo
        
        for button in [undoButton, redoButton] {
            UIView.animate(withDuration: 0.25) {
                button?.alpha = button?.isEnabled ?? false ? 1 : 0.5
            }
        }
    }
    
    func showTutorialIfNeeded(step: Int) {
        
    }
    
    func updateButtons() {
        let buttons = [eraseButton, penButton, magicButton]
        let index = self.selectedAction.rawValue
        self.slider.alpha = index == -1 ? 0.0 : 1.0
        buttons.enumerated().forEach { (obj) in
            self.setButtonStyle(button: obj.element, selected: obj.offset == index)
        }
    }
    
    func setButtonStyle(button: UIButton?, selected: Bool) {
        guard let button = button else { return }
        button.layer.masksToBounds = true
        if selected {
            button.layer.borderWidth = 1
            button.layer.cornerRadius = 6
            button.layer.borderColor = UIColor.white.cgColor
            button.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        } else {
            button.layer.borderWidth = 0
            button.layer.cornerRadius = 0
            button.layer.borderColor = UIColor.clear.cgColor
            button.backgroundColor = UIColor.clear
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.drawingView.frame = self.backgroundImageView.frame
    }
    
    func hiddenShowButtonsWhenDrawing(alpha: CGFloat) {
        self.buttonsView.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            self.buttonsView.alpha = alpha
        }, completion: nil)
    }
    
    func startFadeAnimation() {
        self.hintLabel.layer.removeAllAnimations()
        self.hintLabel.alpha = 0.5
        UIView.animate(withDuration: 2.0, delay: 0.0, options: [.repeat, .autoreverse], animations: {
            self.hintLabel.alpha = 1.0
        }, completion: nil)
    }
    
    func stopFadeAnimation() {
        self.hintLabel.layer.removeAllAnimations()
        self.hintLabel.alpha = 0
    }
    
    func fetchZoomViews(scrollView: UIScrollView) {
        self.zoomImageVC?.setPenSize(penSize: CGFloat(slider.value ), scale: self.scrollView.zoomScale)
        self.zoomImageVC?.scrollView.contentInset = scrollView.contentInset
    }
    
    func fetchPenSize() {
        let size = CGFloat(slider.value) / self.scrollView.zoomScale
        drawingView.userSettings.strokeWidth = size
        self.zoomImageVC?.setPenSize(penSize: size, scale: self.scrollView.zoomScale)
    }
}


extension CutOutViewController: DrawsanaViewDelegate {
  /// When tool changes, update the UI
    func drawsanaView(_ drawsanaView: DrawsanaView, didSwitchTo tool: DrawingTool) {}
    func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeColor strokeColor: UIColor?) {}
    func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFillColor fillColor: UIColor?) {}
    func drawsanaView(_ drawsanaView: DrawsanaView, didChangeStrokeWidth strokeWidth: CGFloat) {}
    func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontName fontName: String) {}
    func drawsanaView(_ drawsanaView: DrawsanaView, didChangeFontSize fontSize: CGFloat) {}
    
    func drawsanaView(_ drawsanaView: DrawsanaView, didStartDragWith tool: DrawingTool) {
        self.hiddenShowButtonsWhenDrawing(alpha: 0)
        self.zoomImageContainer.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2) {
            self.zoomImageContainer.alpha = 1.0
        }
        self.fetchZoomViews(scrollView: self.scrollView)

    }

    func drawsanaView(_ drawsanaView: DrawsanaView, didEndDragWith tool: DrawingTool) {
        self.zoomImageContainer.layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2) {
            self.zoomImageContainer.alpha = 0.0
        }
        
        self.hiddenShowButtonsWhenDrawing(alpha: 1)
        self.showTutorialIfNeeded(step: 1)
    }

    func drawsanaView(_ drawsanaView: DrawsanaView, didDragWith tool: DrawingTool, point: CGPoint) {
//        if let panGR = drawsanaView.panGR {
//            if panGR.hadSecondTouch {
//                self.drawingView.scrollViewPanGesture?.isEnabled = false
//                self.drawingView.scrollViewPanGesture?.isEnabled = true
//  
//                self.drawingView.panGR?.isEnabled = false
//                self.drawingView.panGR?.isEnabled = true
//            }
//        }
        
       var newPosition: CGFloat = 20
       let pointInView = self.drawingView.convert(point, to: self.view)
       if pointInView.x < 120 &&
           pointInView.y < self.zoomImageContainer.frame.width + self.zoomImageContainer.frame.origin.y + 10 {
           newPosition = self.view.frame.width - 120
       }
       if self.zoomContainerViewLeftConstraint.constant != newPosition {
           self.zoomContainerViewLeftConstraint.constant = newPosition
           self.zoomImageContainer.layoutIfNeeded()
       }

       let px = point.x / drawsanaView.frame.size.width
       let py = point.y / drawsanaView.frame.size.height
       let aspect = self.zoomImageScale / self.scrollView.zoomScale
       zoomImageVC?.offset = CGPoint(x: px * self.scrollView.contentSize.width * aspect,
                                     y: py * self.scrollView.contentSize.height * aspect)
       zoomImageVC?.drawingImageView.image = drawsanaView.transientBufferWithShapeInProgress
    }

}

/// Implement `DrawingOperationStackDelegate` to keep the UI in sync with the
/// operation stack
extension CutOutViewController: DrawingOperationStackDelegate {
  func drawingOperationStackDidUndo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        applyUndoViewState()
  }

  func drawingOperationStackDidRedo(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        applyUndoViewState()
  }

  func drawingOperationStackDidApply(_ operationStack: DrawingOperationStack, operation: DrawingOperation) {
        applyUndoViewState()
        self.hiddenShowButtonsWhenDrawing(alpha: 1)
    
  }
}

extension CutOutViewController: QLPreviewControllerDataSource {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    return 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
    return savedImageURL as NSURL
  }
}


extension CutOutViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.fetchZoomViews(scrollView: scrollView)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.fetchZoomViews(scrollView: scrollView)
        self.fetchPenSize()
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        print("scrollViewWillBeginZooming")
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.fetchZoomViews(scrollView: scrollView)
        self.hiddenShowButtonsWhenDrawing(alpha: 1)
    }
}

extension UIImage {
    func masked(with image: UIImage, p: CGPoint? = nil, inverted: Bool = false) -> UIImage? {
        if let cgimage = self.cgImage,
            let imCGimage = image.cgImage,
            let masked = cgimage.masking(imCGimage) {
                return UIImage(cgImage: masked)
        }
        return nil
    }
    
    func maskedImage(mask: UIImage) -> UIImage {
        let maskReference = mask.cgImage!
        let imageMask = CGImage(maskWidth: maskReference.width,
                                height: maskReference.height,
                                bitsPerComponent: maskReference.bitsPerComponent,
                                bitsPerPixel: maskReference.bitsPerPixel,
                                bytesPerRow: maskReference.bytesPerRow,
                                provider: maskReference.dataProvider!, decode: nil, shouldInterpolate: true)

        let maskedReference = self.cgImage?.masking(imageMask!)
        // maskedReference is nil so the next line crashes
        let maskedImage = UIImage(cgImage:maskedReference!, scale: self.scale, orientation: self.imageOrientation)

        return maskedImage
    }
    
    func imageWithColor(tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)

        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(.normal)

        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height) as CGRect
        tintColor.setFill()
        context.fill(rect)
        context.clip(to: rect, mask: self.cgImage!)
        
        UIColor.black.setFill()
        context.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
}
