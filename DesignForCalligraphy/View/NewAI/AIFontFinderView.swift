import SwiftUI

struct AIFontFinderView: View {
    @State private var fontPrompt: String = ""
    @State var selectedImage: NSImage?
    @State var croppedImage: NSImage?
    @State var showcropview: Bool = false
    @State var showresultview: Bool = false
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button(action: {}) {
                    Image("historyIcon")
                        .padding(.trailing, 48)
                        .padding(.top, 22)
                }.buttonStyle(.plain)
            }
            
            // MARK: - Banner
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("purple"))
                .frame(width: 1066, height: 156)
                .overlay(
                    VStack {
                        Text("AI Font Finder")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top,15)
                            .frame(height: 63)
                        Text("Upload an image or screenshot, and let AI find the exact or closest matching font for your projects.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(height: 48)
                    }
                )


            // MARK: - Input Card
            VStack(alignment: .leading, spacing: 12) {

               
                // MARK: Bottom Controls
                HStack(spacing: 12) {
                    // Icons
                    Button(action: openImageFromFinder) {
                        Image(systemName: "camera")
                            .foregroundColor(Color("purple"))
                            .font(.system(size: 18))
                            .frame(width: 48, height: 48)
                            .background(Color(.sRGB, red: 231/255, green: 231/255, blue: 231/255))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    Spacer()

                    // Generate Button
                    Button(action: {
                       showcropview = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Find")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color("purple"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(width: 1066, height: 80)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4)
            .padding(.top, 100)
            Spacer()
        }
        .padding(.top, 20)
        .background(Color(.sRGB, red: 251/255, green: 251/255, blue: 251/255, opacity: 1.0))
        .overlay {
            if showcropview {
                ZStack {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea(.all)
                    CropImageView(selectedImage: $selectedImage){ newImage in
                        croppedImage = newImage
                        showcropview = false
                        showresultview = true
                    }
                }
            }
            if showresultview {
                ZStack {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea(.all)
                    FontResultsView(image: $croppedImage) {
                        showresultview = false
                    }
                }
            }
        }
    }
    private func openImageFromFinder() {
           let panel = NSOpenPanel()
           panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic"]
           panel.allowsMultipleSelection = false
           if panel.runModal() == .OK {
               if let url = panel.url, let image = NSImage(contentsOf: url) {
                   self.selectedImage = image
                   self.showcropview = true
               }
           }
       }
       
       private func resetFlow() {
           self.selectedImage = nil
           self.croppedImage = nil
           self.showcropview = false
           self.showresultview = false
       }
}
struct CropImageView: View {
    @Binding var selectedImage: NSImage?
    @State private var cropRect = CGRect(x: 80, y: 50, width: 200, height: 200)
    
    var onCrop: (NSImage?) -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 20) {
                Text("Crop Selected Image")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                
                ZStack {
                    if let selectedImage {
                        Image(nsImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 500, height: 280)
                            .overlay(
                                CropOverlay(cropRect: $cropRect)
                            )
                    } else {
                        Text("No image selected")
                    }
                }

                HStack(spacing: 40) {
                    PurpleFilledButton(title: "Done") {
                        if let original = selectedImage {
                            let cropped = cropImage(original, rect: cropRect)
                            onCrop(cropped) // ✅ return cropped image
                        }
                    }
                    PurpleOutlineButton(title: "Reset") {
                        cropRect = CGRect(x: 80, y: 50, width: 200, height: 200)
                    }
                }
                .padding(.top, 20)
            }
            .padding(30)
            .frame(width: 900, height: 460)
            .background(Color(.sRGB, red: 247/255, green: 245/255, blue: 248/255))
            .cornerRadius(16)
            
            // Close button
            Button(action: { }) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .padding(.trailing, 30)
                    .padding(.top, 20)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func cropImage(_ image: NSImage, rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        
        // Convert cropRect from SwiftUI space to CGImage space
        let scaleX = CGFloat(cgImage.width) / 500.0   // 500 is your display width
        let scaleY = CGFloat(cgImage.height) / 280.0  // 280 is your display height
        let scaledRect = CGRect(
            x: rect.origin.x * scaleX,
            y: rect.origin.y * scaleY,
            width: rect.size.width * scaleX,
            height: rect.size.height * scaleY
        )
        
        guard let cropped = cgImage.cropping(to: scaledRect) else { return nil }
        return NSImage(cgImage: cropped, size: scaledRect.size)
    }
}

struct CropOverlay: View {
    @Binding var cropRect: CGRect
    @State private var initialRect: CGRect = .zero
    let imageSize = CGSize(width: 500, height: 280) // 👈 match display size
    
    var body: some View {
        ZStack {
            // Crop rectangle
            Rectangle()
                .path(in: cropRect)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(.black)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newRect = initialRect.offsetBy(
                                dx: value.translation.width,
                                dy: value.translation.height
                            )
                            cropRect = clampRect(newRect, in: imageSize)
                        }
                        .onEnded { _ in
                            initialRect = cropRect
                        }
                )
                .onAppear {
                    initialRect = cropRect
                }
            
            // Corner handles
            ForEach(0..<4) { i in
                Circle()
                    .fill(Color("purple"))
                    .frame(width: 16, height: 16)
                    .position(positionForCorner(index: i, in: cropRect))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                var newRect = initialRect
                                resizeRect(&newRect, corner: i, drag: value.translation)
                                cropRect = clampRect(newRect, in: imageSize)
                            }
                            .onEnded { _ in
                                initialRect = cropRect
                            }
                    )
            }
        }
    }
    
    private func positionForCorner(index: Int, in rect: CGRect) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: rect.minX, y: rect.minY) // top-left
        case 1: return CGPoint(x: rect.maxX, y: rect.minY) // top-right
        case 2: return CGPoint(x: rect.minX, y: rect.maxY) // bottom-left
        default: return CGPoint(x: rect.maxX, y: rect.maxY) // bottom-right
        }
    }
    
    private func resizeRect(_ rect: inout CGRect, corner: Int, drag: CGSize) {
        switch corner {
        case 0: // top-left
            rect.origin.x += drag.width
            rect.origin.y += drag.height
            rect.size.width -= drag.width
            rect.size.height -= drag.height
        case 1: // top-right
            rect.origin.y += drag.height
            rect.size.width += drag.width
            rect.size.height -= drag.height
        case 2: // bottom-left
            rect.origin.x += drag.width
            rect.size.width -= drag.width
            rect.size.height += drag.height
        case 3: // bottom-right
            rect.size.width += drag.width
            rect.size.height += drag.height
        default: break
        }
    }
    
    private func clampRect(_ rect: CGRect, in bounds: CGSize) -> CGRect {
        var r = rect
        
        // Prevent negative width/height
        if r.width < 40 { r.size.width = 40 }
        if r.height < 40 { r.size.height = 40 }
        
        // Clamp within image
        if r.minX < 0 { r.origin.x = 0 }
        if r.minY < 0 { r.origin.y = 0 }
        if r.maxX > bounds.width { r.origin.x = bounds.width - r.width }
        if r.maxY > bounds.height { r.origin.y = bounds.height - r.height }
        
        return r
    }
}



struct FontResultsView: View {
    @Binding var image: NSImage?
    let action:() -> Void
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Results")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                
                // Cropped image preview
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 120)
                   .cornerRadius(8)
                 }
                
                Text("What font is used in this image?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                VStack(spacing: 16) {
                    FontResultRow(fontName: "Pacifico")
                    FontResultRow(fontName: "Playball Formal Script")
                }
                
                Spacer()
            }
            .padding(30)
            .frame(width: 900, height: 500)
            .background(Color(.sRGB, red: 247/255, green: 245/255, blue: 248/255))
            .cornerRadius(16)
            
            Button(action: {action()}) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .padding(.trailing, 30)
                    .padding(.top, 20)
            }
            .buttonStyle(.plain)
        }
    }
}

struct FontResultRow: View {
    let fontName: String
    
    var body: some View {
        HStack {
            Text(fontName)
                .font(.custom(fontName, size: 22)) // Demo using font
                .foregroundColor(.black)
            Spacer()
            Button(action: {}) {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.black)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
    }
}
struct PurpleFilledButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color("purple"))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct PurpleOutlineButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("purple"))
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("purple"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
