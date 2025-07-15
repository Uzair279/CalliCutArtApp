
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
