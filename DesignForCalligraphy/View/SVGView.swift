import SwiftUI
import SVGKit
import AppKit


// MARK: - SwiftUI wrapper for NSView displaying SVG and handling gestures
struct SVGCanvasView: NSViewRepresentable {
    let svgURL: URL
    var onCreateView: ((SVGCanvasNSView) -> Void)?
    
    func makeNSView(context: Context) -> SVGCanvasNSView {
        let view = SVGCanvasNSView()
        onCreateView?(view)
        return view
    }
    
    func updateNSView(_ nsView: SVGCanvasNSView, context: Context) {
       
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: SVGCanvasView
        init(_ parent: SVGCanvasView) {
            self.parent = parent
        }
    }
}

// MARK: - NSView displaying SVG and handling gestures & Undo
class SVGCanvasNSView: NSView, ObservableObject {
    let BackgroundID = "DesignForCalligraphy.SVGCanvasNSView"
    @Published var sublayers: [CALayer] = []
    func updateSublayers() {
        let layers = svgRootLayer?.sublayers ?? []
        self.sublayers = layers
        var editType: String = "background"
        if let selected = selectedLayer, selected is CATextLayer {
            editType = "text"
        }
        
        NotificationCenter.default.post(
            name: .didUpdateSublayers,
            object: nil,
            userInfo: ["editType": editType]
        )
    }
    
    var svgImage: SVGKImage?
    var svgRootLayer: CALayer?
    
    var selectedLayer: CALayer? {
        didSet {
            // Remove border from previously selected layer
            oldValue?.borderWidth = 0
            oldValue?.borderColor = nil
            
            // Apply blue border to new selection
            selectedLayer?.borderWidth = 1
            selectedLayer?.borderColor = NSColor.systemBlue.cgColor
            self.updateSublayers()
        }
    }
    
    private var originalTransform: CGAffineTransform?
    
    var externalUndoManager: UndoManager?
    
    override var undoManager: UndoManager? {
        externalUndoManager ?? super.undoManager
    }
    func resetAll() {
        if let undoManager {
            while undoManager.canUndo {
                undoManager.undo()
            }
            undoManager.removeAllActions()
        }
        selectedLayer = nil
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupGestureRecognizers()
    }
    
    func loadSVG(url: URL) {
        svgRootLayer?.removeFromSuperlayer()
        
        svgImage = SVGKImage(contentsOf: url)
        guard let svgImage = svgImage else { return }
        
        // Set the SVG image size to fit the view
        let targetSize = bounds.size
        let aspectRatio = svgImage.size.width / svgImage.size.height
        var newSize = CGSize(width: targetSize.width, height: targetSize.height)
        
        // Maintain aspect ratio
        if targetSize.width / targetSize.height > aspectRatio {
            newSize.width = targetSize.height * aspectRatio
        } else {
            newSize.height = targetSize.width / aspectRatio
        }
        
        svgImage.size = newSize
        
        svgRootLayer = svgImage.caLayerTree
//        svgRootLayer?.frame.size = CGSize(width: 500, height: 400)
        self.updateSublayers()
        clearAllTransforms(in: svgRootLayer)
        guard let svgRootLayer = svgRootLayer else { return }
        
        // Center the layer in the view
        svgRootLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        svgRootLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        let flip = CGAffineTransform(scaleX: 1, y: -1)
        svgRootLayer.setAffineTransform(flip)
        layer?.sublayers?.removeAll()
        layer?.addSublayer(svgRootLayer)
        
        selectedLayer = nil
        originalTransform = nil
        setupLayerHitTesting(svgRootLayer)
        setNeedsDisplay(bounds)
    }
    
    
    
    private func setupLayerHitTesting(_ layer: CALayer?) {
        guard let layer = layer else { return }
        layer.isGeometryFlipped = true
        layer.isOpaque = false
        layer.masksToBounds = false
        layer.contentsGravity = .resizeAspect
        layer.isHidden = false
        layer.allowsGroupOpacity = false
        layer.sublayers?.forEach { setupLayerHitTesting($0) }
    }
    
    // MARK: - Select layer on mouse down
    @objc private func handleClick(_ gesture: NSClickGestureRecognizer) {
        let clickPoint = gesture.location(in: self)

        if let layers = svgRootLayer?.sublayers?.reversed() { // topmost first
            for sub in layers {
                if sub.name != BackgroundID {
                    // Convert click point to the layer's coordinate space
                    let localPoint = sub.convert(clickPoint, from: self.layer)

                    // Manual bounds check
                    if sub.bounds.contains(localPoint) {
                        selectedLayer = sub
                        originalTransform = sub.affineTransform()
                        break
                    }
                    else {
                        selectedLayer = nil
                    }
                }
                else {
                    selectedLayer = nil
                }
            }
            NotificationCenter.default.post(
                name: NSNotification.Name("LayerSelectionChanged"),
                object: self,
                userInfo: ["layer": self.selectedLayer]
            )

        }
    }
    
    // MARK: - Gesture Recognizers
    private func setupGestureRecognizers() {
        // Pan (drag) gesture
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        // Magnification (pinch zoom) gesture
        let magnifyGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handleMagnify(_:)))
        addGestureRecognizer(magnifyGesture)
        
        // Rotation gesture
        let rotateGesture = NSRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
        addGestureRecognizer(rotateGesture)
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        addGestureRecognizer(clickGesture)
    }
    
    // MARK: - Gesture handlers
    
    @objc private func handlePan(_ gesture: NSPanGestureRecognizer) {
        guard let layer = selectedLayer else { return }
        
        if gesture.state == .began {
            originalTransform = layer.affineTransform()
        }
        
        let translation = gesture.translation(in: self)
        var t = originalTransform ?? .identity
        t = t.translatedBy(x: translation.x, y: translation.y)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.setAffineTransform(t)
        CATransaction.commit()
        
        if gesture.state == .ended || gesture.state == .cancelled {
            registerUndo(for: layer,
                         oldTransform: originalTransform ?? .identity,
                         newTransform: layer.affineTransform())
            originalTransform = nil
        }
    }
    
    
    @objc private func handleMagnify(_ gesture: NSMagnificationGestureRecognizer) {
        guard let layer = selectedLayer else { return }
        
        if gesture.state == .began {
            originalTransform = layer.affineTransform()
        }
        
        let scale = 1 + gesture.magnification
        var t = originalTransform ?? .identity
        t = t.scaledBy(x: scale, y: scale)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.setAffineTransform(t)
        CATransaction.commit()
        
        if gesture.state == .ended || gesture.state == .cancelled {
            registerUndo(for: layer,
                         oldTransform: originalTransform ?? .identity,
                         newTransform: layer.affineTransform())
            originalTransform = nil
        }
    }
    
    
    @objc private func handleRotate(_ gesture: NSRotationGestureRecognizer) {
        guard let layer = selectedLayer else { return }
        
        if gesture.state == .began {
            originalTransform = layer.affineTransform()
        }
        
        let rotation = gesture.rotation
        var t = originalTransform ?? .identity
        t = t.rotated(by: rotation)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.setAffineTransform(t)
        CATransaction.commit()
        
        if gesture.state == .ended || gesture.state == .cancelled {
            registerUndo(for: layer,
                         oldTransform: originalTransform ?? .identity,
                         newTransform: layer.affineTransform())
            originalTransform = nil
        }
    }
    
    
    // MARK: - Undo registration
    
    private func registerUndo(for layer: CALayer, oldTransform: CGAffineTransform, newTransform: CGAffineTransform) {
        guard let undoManager = undoManager else { return }
        
        undoManager.registerUndo(withTarget: layer) { targetLayer in
            targetLayer.setAffineTransform(oldTransform)
            
            // Register redo
            self.registerUndo(for: layer, oldTransform: newTransform, newTransform: oldTransform)
        }
        undoManager.setActionName("Transform Change")
    }
    
    // MARK: - Resize root layer on view resize
    override func layout() {
        super.layout()

        if let image = svgImage {
            // Force the SVG to render at our view's current size
            image.size = bounds.size

            // Make sure the root layer stays centered
            svgRootLayer?.position = CGPoint(x: bounds.midX, y: bounds.midY)
        }
    }
    func clearAllTransforms(in layer: CALayer?) {
        guard let layer = layer else { return }
        layer.setAffineTransform(.identity)
        layer.transform = CATransform3DIdentity
        layer.sublayers?.forEach { clearAllTransforms(in: $0) }
    }
    func deleteLayer(_ layer: CALayer) {
        guard let parent = layer.superlayer,
              let undoManager = undoManager,
              let index = parent.sublayers?.firstIndex(where: { $0 === layer }) else {
            return
        }
        
        // Remove the layer
        layer.removeFromSuperlayer()
        updateSublayers()
        
        // Register undo
        undoManager.registerUndo(withTarget: self) { targetSelf in
            parent.insertSublayer(layer, at: UInt32(index))
            targetSelf.updateSublayers()
            // Register redo
           
            targetSelf.undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                self.deleteLayer(layer)
            }
        }
        
        undoManager.setActionName("Delete Layer")
    }
    func toggleLayerVisibility(_ layer: CALayer) {
        let oldHidden = layer.isHidden
        if oldHidden == false {
            layer.isHidden = true
        }
        else {
            layer.isHidden = false
        }
        undoManager?.registerUndo(withTarget: self) { target in
            layer.isHidden = oldHidden
            target.undoManager?.registerUndo(withTarget: target) { redSelf in
                self.toggleLayerVisibility(layer)
            }
        }
        
        undoManager?.setActionName(layer.isHidden ? "Hide Layer" : "Show Layer")
    }
    func toggleLayerLock(_ layer: CALayer) {
        let wasLocked = (layer.value(forKey: "isLocked") as? Bool) ?? false
        layer.setValue(!wasLocked, forKey: "isLocked")

        undoManager?.registerUndo(withTarget: self) { [wasLocked] target in
            layer.setValue(wasLocked, forKey: "isLocked")

            target.undoManager?.registerUndo(withTarget: target) { [wasLocked] redoTarget in
                layer.setValue(!wasLocked, forKey: "isLocked")

                // Register again for infinite undo/redo
                redoTarget.undoManager?.registerUndo(withTarget: redoTarget) { finalTarget in
                    finalTarget.toggleLayerLock(layer)
                }
            }
        }

        undoManager?.setActionName(wasLocked ? "Unlock Layer" : "Lock Layer")
    }
    func addTextLayer(_ text: String) {
        guard let root = svgRootLayer else { return }

        let textLayer = FlippedTextLayer()
        textLayer.frame.origin = CGPoint(
            x: root.bounds.midX - 100,
            y: root.bounds.midY - 20
        )

        let font = NSFont(name: "SF Pro Text", size: 30)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        textLayer.string = string
        textLayer.font = font
        textLayer.fontSize = 30
        textLayer.frame.size = string.size()
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        root.addSublayer(textLayer)
        updateSublayers()
        setNeedsDisplay(bounds)
        self.selectedLayer = textLayer
        // Undo support
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            textLayer.removeFromSuperlayer()
            targetSelf.updateSublayers()
            targetSelf.undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                self.addTextLayer(text)
            }
        }
        
        undoManager?.setActionName("Add Text Layer")
    }
    func addImageLayerFromFinder() {
        let panel = NSOpenPanel()
        panel.title = "Choose an Image"
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff", "bmp", "gif", "heic"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        panel.begin { [weak self] response in
            guard response == .OK,
                  let url = panel.url,
                  let self = self,
                  let image = NSImage(contentsOf: url),
                  let fixedImage = self.rotateAndFixImage(image),
                  let undoManager = self.undoManager else {
                return
            }
            
            let imageLayer = CALayer()
            imageLayer.contents = fixedImage
            imageLayer.frame = CGRect(x: 100, y: 100, width: fixedImage.size.width / 2, height: fixedImage.size.height / 2)
            imageLayer.contentsGravity = .resizeAspect
            imageLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            addImageLayerToCanvas(imageLayer)
        }
    }
    func addImageLayerToCanvas(_ layer: CALayer) {
        self.svgRootLayer?.addSublayer(layer)
        self.updateSublayers()
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            layer.removeFromSuperlayer()
            targetSelf.updateSublayers()
            targetSelf.undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                self.addImageLayerToCanvas(layer)
            }
        }
    }
    func rotateAndFixImage(_ image: NSImage) -> NSImage? {
        let size = image.size
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        
        let transform = NSAffineTransform()
        
        // Translate to image center
        transform.translateX(by: size.width / 2, yBy: size.height / 2)
        
        // Rotate 180 degrees
        transform.rotate(byDegrees: 180)
        
        // Flip horizontally by scaling X
        transform.scaleX(by: -1.0, yBy: 1.0)
        
        // Move back after transform
        transform.translateX(by: -size.width / 2, yBy: -size.height / 2)
        
        transform.concat()
        
        image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        
        newImage.unlockFocus()
        return newImage
    }
    func changeBackgroundColor(_ color: NSColor) {
        guard let backgroundLayer = self.svgRootLayer else { return }
        
        let oldColor = NSColor(cgColor: backgroundLayer.backgroundColor ?? NSColor.clear.cgColor) ?? .clear
        backgroundLayer.backgroundColor = color.cgColor
        
        undoManager?.registerUndo(withTarget: self) { [oldColor, color] target in
            // Undo: restore the old color
            target.svgRootLayer?.backgroundColor = oldColor.cgColor
            
            // Register redo
            target.undoManager?.registerUndo(withTarget: target) { redoTarget in
                // Redo: restore the new color
                redoTarget.svgRootLayer?.backgroundColor = color.cgColor
                
                // Register undo again for infinite undo/redo
                redoTarget.undoManager?.registerUndo(withTarget: redoTarget) { finalTarget in
                    finalTarget.changeBackgroundColor(oldColor)
                }
            }
        }
    }
    func changeShapeColor(_ color: NSColor, layer: CALayer?) {
        guard let layer = layer,  let shapeLayer = layer as? CAShapeLayer else { showAlert(title: "No Shape Layer Selected", message: "Please selected a shape layer")
            return }
        
        let oldColor = NSColor(cgColor: shapeLayer.fillColor ?? NSColor.black.cgColor) ?? .clear
        shapeLayer.fillColor = color.cgColor
        
        undoManager?.registerUndo(withTarget: self) { [oldColor, color] target in
            // Undo: restore the old color
            shapeLayer.fillColor = oldColor.cgColor
            
            // Register redo
            target.undoManager?.registerUndo(withTarget: target) { redoTarget in
                // Redo: restore the new color
                shapeLayer.fillColor  = color.cgColor
                
                // Register undo again for infinite undo/redo
                redoTarget.undoManager?.registerUndo(withTarget: redoTarget) { finalTarget in
                    finalTarget.changeShapeColor(oldColor, layer: layer)
                }
            }
        }
    }
    func changeTextColor(_ color: NSColor) {
        guard let textLayer = selectedLayer as? CATextLayer,
              let attributedString = textLayer.string as? NSAttributedString else {
            print("Invalid layer or no attributed text")
            return
        }

        let oldAttributedString = attributedString

        let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttrString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutableAttrString.length))
        textLayer.string = mutableAttrString
        textLayer.frame.size = mutableAttrString.size()

        undoManager?.registerUndo(withTarget: self) { target in
            target.setTextLayerAttributedString(oldAttributedString)
            target.undoManager?.registerUndo(withTarget: target) { redoTarget in
                redoTarget.changeTextColor(color)
            }
        }
        undoManager?.setActionName("Change Text Color")
    }

    func changeFontSizeAttribute(_ newFontSize: CGFloat) {
        guard let textLayer = selectedLayer as? CATextLayer,
              let attributedString = textLayer.string as? NSAttributedString else {
            print("Invalid layer or no attributed text")
            return
        }

        let oldAttributedString = attributedString

        let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttrString.enumerateAttribute(.font, in: NSRange(location: 0, length: mutableAttrString.length)) { value, range, _ in
            if let oldFont = value as? NSFont {
                let newFont = NSFont(descriptor: oldFont.fontDescriptor, size: newFontSize) ?? NSFont.systemFont(ofSize: newFontSize)
                mutableAttrString.addAttribute(.font, value: newFont, range: range)
            }
        }

        textLayer.string = mutableAttrString
        textLayer.frame.size = mutableAttrString.size()

        undoManager?.registerUndo(withTarget: self) { target in
            target.setTextLayerAttributedString(oldAttributedString)
            target.undoManager?.registerUndo(withTarget: target) { redoTarget in
                redoTarget.changeFontSizeAttribute(newFontSize)
            }
        }
        undoManager?.setActionName("Change Font Size")
    }
    func setTextLayerAttributedString(_ attributedString: NSAttributedString) {
        guard let textLayer = self.selectedLayer as? CATextLayer else { return }
        textLayer.string = attributedString
        textLayer.frame.size = attributedString.size()
    }
    func changeFontUsingAttributes(newFont: NSFont) {
        guard let textLayer = selectedLayer as? CATextLayer,
              let attributedString = textLayer.string as? NSAttributedString else {
            print("Invalid layer or no attributed text")
            return
        }

        let oldAttributedString = attributedString

        let mutableAttrString = NSMutableAttributedString(attributedString: attributedString)
        mutableAttrString.enumerateAttribute(.font, in: NSRange(location: 0, length: mutableAttrString.length)) { _, range, _ in
            mutableAttrString.addAttribute(.font, value: newFont, range: range)
        }

        textLayer.string = mutableAttrString
        textLayer.frame.size = mutableAttrString.size()

        undoManager?.registerUndo(withTarget: self) { target in
            target.setTextLayerAttributedString(oldAttributedString)
            target.undoManager?.registerUndo(withTarget: target) { redoTarget in
                redoTarget.changeFontUsingAttributes(newFont: newFont)
            }
        }
        undoManager?.setActionName("Change Font")
    }


}
class FlippedTextLayer: CATextLayer {
    override func draw(in ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        super.draw(in: ctx)
        ctx.restoreGState()
    }
}
