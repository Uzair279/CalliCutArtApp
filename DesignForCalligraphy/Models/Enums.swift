
import Foundation
import AppKit
import SVGKit
import StoreKit

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

extension Product {
    func planType(comparedTo products: [Product]) -> String {
        if let intro = self.subscription?.introductoryOffer,
           intro.paymentMode == .freeTrial {
            return "Free Trial"
        }
        guard let index = products.firstIndex(where: { $0.id == self.id }),
              let baseProduct = products.first,
              let basePrice = (baseProduct.price as NSDecimalNumber?)?.doubleValue else {
            return "Unknown"
        }

        let thisPrice = (self.price as NSDecimalNumber).doubleValue

        switch index {
        case 0:
            return "Basic"
        case 1:
            // Monthly (~4 weeks)
            let costPerWeek = thisPrice / 4
            let discount = (1 - (costPerWeek / basePrice)) * 100
            return String(format: "%.0f%% Off", max(discount, 0))
        case 2:
            // Yearly (~52 weeks)
            let costPerWeek = thisPrice / 52
            let discount = (1 - (costPerWeek / basePrice)) * 100
            return String(format: "%.0f%% Off", max(discount, 0))
        case 3:
            return "One Time"
        default:
            return "Standard"
        }
    }
    func planName(from productIDs: [String]) -> String {
        guard let index = productIDs.firstIndex(of: self.id) else {
            return "Unknown"
        }
        
        switch index {
        case 0: return "Weekly"
        case 1: return "Monthly"
        case 2: return "Yearly"
        case 3: return "Lifetime"
        default: return "Unknown"
        }
    }
    var trialDescription: String? {
        guard let intro = self.subscription?.introductoryOffer,
              intro.paymentMode == .freeTrial else {
            return nil
        }

        let period = intro.period
        let value = period.value

        let unitString: String = {
            switch period.unit {
            case .day: return value == 1 ? "day" : "days"
            case .week: return value == 1 ? "week" : "weeks"
            case .month: return value == 1 ? "month" : "months"
            case .year: return value == 1 ? "year" : "years"
            @unknown default: return "days"
            }
        }()

        return "Try Free for \(value) \(unitString) then \(self.displayPrice)"
    }
}

