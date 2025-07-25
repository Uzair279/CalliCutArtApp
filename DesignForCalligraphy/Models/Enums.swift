
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
        image.lockFocus()
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()

        // Fit the layer into the image rect
        let scaleX = size.width / bounds.width
        let scaleY = size.height / bounds.height
        context?.scaleBy(x: scaleX, y: scaleY)
        render(in: context!)

        context?.restoreGState()
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
