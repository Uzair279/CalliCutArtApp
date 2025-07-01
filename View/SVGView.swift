import SVGKit
import SwiftUI

struct SVGView: NSViewRepresentable {
    let svgURL: URL
    let size: CGSize // Pass size explicitly to constrain dimensions

    func makeNSView(context: Context) -> SVGKFastImageView {
        let svgImage = SVGKImage(contentsOf: svgURL)
        let svgView = SVGKFastImageView(svgkImage: svgImage)
        svgView?.translatesAutoresizingMaskIntoConstraints = false

        // Set a default size if no size is provided
        svgView?.image.size = size
        return svgView ?? SVGKFastImageView()
    }

    func updateNSView(_ nsView: SVGKFastImageView, context: Context) {
        if let svgImage = SVGKImage(contentsOf: svgURL) {
            svgImage.size = size
            nsView.image = svgImage
        }
    }
}
