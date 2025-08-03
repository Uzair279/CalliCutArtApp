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
        nsView.loadSVG(url: svgURL)
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
        }
    }
    
    private var originalTransform: CGAffineTransform?
    
    var externalUndoManager: UndoManager?
    
    override var undoManager: UndoManager? {
        externalUndoManager ?? super.undoManager
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
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let hitLayer = layer?.hitTest(point), hitLayer != svgRootLayer else {
            selectedLayer = nil
            originalTransform = nil
            return
        }
        if hitLayer.name != BackgroundID {
            selectedLayer = hitLayer
            originalTransform = hitLayer.affineTransform()
            
            // Make sure anchorPoint is center for natural rotation/scaling
            setAnchorPointToCenter(for: hitLayer)
        }
    }
    
    private func setAnchorPointToCenter(for layer: CALayer) {
        let bounds = layer.bounds
        let oldAnchorPoint = layer.anchorPoint
        let oldPosition = layer.position

        // Calculate new anchor point and the difference
        let newAnchorPoint = CGPoint(x: 0.5, y: 0.5)
        let anchorDelta = CGPoint(
            x: newAnchorPoint.x - oldAnchorPoint.x,
            y: newAnchorPoint.y - oldAnchorPoint.y
        )

        // Convert the delta into position offset
        let offset = CGPoint(
            x: bounds.size.width * anchorDelta.x,
            y: bounds.size.height * anchorDelta.y
        )

        // Apply transform if any
        var transformedOffset = offset
        if let _ = layer.presentation(), layer.affineTransform() != .identity {
            transformedOffset = offset.applying(layer.affineTransform())
        }

        // Adjust the position
        layer.anchorPoint = newAnchorPoint
        layer.position = CGPoint(
            x: oldPosition.x + transformedOffset.x,
            y: oldPosition.y + transformedOffset.y
        )
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
        // Optionally trigger a new layout pass if needed
        if let image = svgImage {
            image.scaleToFit(inside: bounds.size)
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
        let textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 50, y: 50, width: 200, height: 40)
        
        let font = NSFont.systemFont(ofSize: 18)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        textLayer.string = NSAttributedString(string: text, attributes: attributes)
        textLayer.font = font
        textLayer.fontSize = 18
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        textLayer.alignmentMode = .left
        textLayer.isWrapped = true
        
        // ✅ Fix flipped text caused by flipped root layer
        textLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
        textLayer.isGeometryFlipped = true
        
        root.addSublayer(textLayer)
        updateSublayers()
        setNeedsDisplay(bounds)
        
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
    
    
}
