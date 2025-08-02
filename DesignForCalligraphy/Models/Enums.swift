
import Foundation
import AppKit
import SVGKit

enum screen{
    case home
    case canvas
}
enum SVGElementType {
    case path, text
}

extension SVGKImage {
    func scaleToFit(inside maxSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let scale = min(maxSize.width / size.width, maxSize.height / size.height)
        self.scale = scale
    }
}
extension CALayer {
    func snapshotImage(size: CGSize) -> NSImage? {
        let image = NSImage(size: size)
        image.lockFocusFlipped(true) // flip coordinates
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        context.saveGState()

        // Center the layer in the image and fit it
        let scaleX = size.width / bounds.width
        let scaleY = size.height / bounds.height
        let scale = min(scaleX, scaleY)

        // Translate and scale to center and fit layer
        context.translateBy(x: (size.width - bounds.width * scale) / 2,
                            y: (size.height - bounds.height * scale) / 2)
        context.scaleBy(x: scale, y: scale)

        // Render the layer
        render(in: context)

        context.restoreGState()
        image.unlockFocus()
        return image
    }
}

extension CALayer {
    func snapshot(scale: CGFloat = 1.0) -> NSImage? {
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        rep.size = bounds.size

        NSGraphicsContext.saveGraphicsState()
        if let context = NSGraphicsContext(bitmapImageRep: rep) {
            NSGraphicsContext.current = context
            context.cgContext.scaleBy(x: scale, y: scale)
            render(in: context.cgContext)
            context.flushGraphics()
        }
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }
}
enum Fonts : String {
    case bold = "SFProText-Bold"
    case medium = "SFProText-Medium"
    case regular = "SFProText-Regular"
}

