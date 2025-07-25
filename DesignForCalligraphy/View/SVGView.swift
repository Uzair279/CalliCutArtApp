import SwiftUI
import SVGKit
import AppKit


// MARK: - SwiftUI wrapper for NSView displaying SVG and handling gestures
struct SVGCanvasView: NSViewRepresentable {
    let svgURL: URL
//    @Environment(\.undoManager) var undoManager
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
class SVGCanvasNSView: NSView {
    var svgImage: SVGKImage?
    var svgRootLayer: CALayer?

    private var selectedLayer: CALayer?
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
        selectedLayer = hitLayer
        originalTransform = hitLayer.affineTransform()

        // Make sure anchorPoint is center for natural rotation/scaling
        setAnchorPointToCenter(for: hitLayer)
    }

    private func setAnchorPointToCenter(for layer: CALayer) {
        let center = CGPoint(x: layer.bounds.midX, y: layer.bounds.midY)
        let oldPosition = layer.position
        let oldAnchor = layer.anchorPoint

        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        // Adjust position to keep visual position the same after changing anchor
        let newPosition = CGPoint(
            x: oldPosition.x + (center.x - layer.bounds.origin.x) * (oldAnchor.x - layer.anchorPoint.x),
            y: oldPosition.y + (center.y - layer.bounds.origin.y) * (oldAnchor.y - layer.anchorPoint.y)
        )
        layer.position = newPosition
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
        let translation = gesture.translation(in: self)

        if gesture.state == .began {
            originalTransform = layer.affineTransform()
        }

        // Apply translation
        var t = originalTransform ?? .identity
        t = t.translatedBy(x: translation.x, y: translation.y)
        layer.setAffineTransform(t)

        if gesture.state == .ended || gesture.state == .cancelled {
            registerUndo(for: layer, oldTransform: originalTransform ?? .identity, newTransform: layer.affineTransform())
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
        layer.setAffineTransform(t)

        if gesture.state == .ended || gesture.state == .cancelled {
            registerUndo(for: layer, oldTransform: originalTransform ?? .identity, newTransform: layer.affineTransform())
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
        layer.setAffineTransform(t)

        if gesture.state == .ended || gesture.state == .cancelled {
            registerUndo(for: layer, oldTransform: originalTransform ?? .identity, newTransform: layer.affineTransform())
            originalTransform = nil
        }
    }

    // MARK: - Undo registration

    private func registerUndo(for layer: CALayer, oldTransform: CGAffineTransform, newTransform: CGAffineTransform) {
        guard let undoManager = undoManager else { return }

        undoManager.registerUndo(withTarget: layer) { targetLayer in
            let currentTransform = targetLayer.affineTransform()
            targetLayer.setAffineTransform(oldTransform)

            // Register redo
            self.undoManager?.registerUndo(withTarget: targetLayer) { redoLayer in
                redoLayer.setAffineTransform(currentTransform)
            }
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

        // Register undo
        undoManager.registerUndo(withTarget: self) { targetSelf in
            parent.insertSublayer(layer, at: UInt32(index))

            // Register redo
            targetSelf.undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                layer.removeFromSuperlayer()
            }
        }

        undoManager.setActionName("Delete Layer")
    }
    func toggleLayerVisibility(_ layer: CALayer) {
        let oldHidden = layer.isHidden
        layer.isHidden.toggle()

        undoManager?.registerUndo(withTarget: self) { target in
            layer.isHidden = oldHidden
            target.toggleLayerVisibility(layer) // redo
        }

        undoManager?.setActionName(layer.isHidden ? "Hide Layer" : "Show Layer")
    }
    func toggleLayerLock(_ layer: CALayer) {
        let wasLocked = layer.name == "locked"
        layer.name = wasLocked ? nil : "locked"

        undoManager?.registerUndo(withTarget: self) { target in
            layer.name = wasLocked ? "locked" : nil
            target.toggleLayerLock(layer) // redo
        }

        undoManager?.setActionName(wasLocked ? "Unlock Layer" : "Lock Layer")
    }
    func addTextLayer(_ text: String) {
        guard let undoManager = undoManager else { return }
        guard let parent = layer?.superlayer else { return }
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = 18
        textLayer.foregroundColor = NSColor.labelColor.cgColor
        textLayer.alignmentMode = .left
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        textLayer.frame = CGRect(x: 50, y: 50, width: 200, height: 40)

        parent.addSublayer(textLayer)

        // Register undo
        undoManager.registerUndo(withTarget: self) { targetSelf in
            textLayer.removeFromSuperlayer()

            // Register redo
            targetSelf.undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                parent.addSublayer(textLayer)
            }
        }

        undoManager.setActionName("Add Text Layer")
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
                  let rotatedImage = self.rotateImage180(image),
                  let undoManager = self.undoManager else {
                return
            }

            let imageLayer = CALayer()
            imageLayer.contents = rotatedImage
            imageLayer.frame = CGRect(x: 100, y: 100, width: rotatedImage.size.width, height: rotatedImage.size.height)
            imageLayer.contentsGravity = .resizeAspect
            imageLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0

            self.svgRootLayer?.addSublayer(imageLayer)

            // Undo support
            undoManager.registerUndo(withTarget: self) { targetSelf in
                imageLayer.removeFromSuperlayer()

                // Redo support
                targetSelf.undoManager?.registerUndo(withTarget: targetSelf) { redoSelf in
                    redoSelf.svgRootLayer?.addSublayer(imageLayer)
                }
            }

            undoManager.setActionName("Add Rotated Image Layer")
        }
    }

    func rotateImage180(_ image: NSImage) -> NSImage? {
        let newSize = image.size
        let rotatedImage = NSImage(size: newSize)

        rotatedImage.lockFocus()
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high

        let transform = NSAffineTransform()
        transform.translateX(by: newSize.width, yBy: newSize.height)
        transform.rotate(byDegrees: 180) // Only rotation, no flipping
        transform.concat()

        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: newSize),
                   operation: .copy,
                   fraction: 1.0)

        rotatedImage.unlockFocus()
        return rotatedImage
    }

}
