import SwiftUI

struct DownloadPopupView: View {
    @Binding var svgURL: URL
    @Binding var imageURL: URL
    let prompt: String
    let selectedImage: NSImage?
    let hideScreen:() -> Void
    @State var showPremiumScreen:  Bool = false
    @State var showLoader: Bool = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            HStack(spacing: 40) {
                
                // MARK: - Left: SVG Image + Share/Upload
                VStack(spacing: 24) {
                    if let nsImage = NSImage(contentsOf: imageURL) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    HStack(spacing: 20) {
                        SmallIconButton(systemName: "square.and.arrow.up") {
                            shareFile(svgURL)
                        }
                    }
                }
                
                // MARK: - Right: Download Section
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Ready for Download!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Download your stunning AI-generated SVG now\nCongratulations on creating your AI-generated SVG masterpiece!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Credits
                    HStack {
                        Text("Free Credits Remaining :")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                        Text("1")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(6)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    // Download + Print
                    HStack(spacing: 16) {
                        PurpleButton(icon: "arrow.down.circle", text: "Download") {
                            saveToUserLocation(svgURL)
                        }
                        PurpleButton(icon: "arrow.trianglehead.clockwise.rotate.90", text: "Regenrate") {
                            regenerateSVG()
                        }
                    }
                    
                    // Upgrade Button
                    Button(action: {
                        showPremiumScreen = true
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("Upgrade Now")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("purple"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .padding(.top, 16)
                
                Spacer()
            }
            .padding(40)
            .background(Color(.sRGB, red: 247/255, green: 245/255, blue: 248/255))
            .cornerRadius(20)
            
            // MARK: - Close Button
            Button(action: {
                hideScreen()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.trailing, 45)
                    .padding(.top, 30)
            }
            .buttonStyle(.plain)
            if showLoader {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .frame(width: 900, height: 453)
        .cornerRadius(16)
        .sheet(isPresented: $showPremiumScreen) {
            SubscriptionView(showPremium: $showPremiumScreen)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

struct PurpleButton: View {
    let icon: String
    let text: String
    let action: ()-> Void
    var body: some View {
        Button(action: {action()}) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(text)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color("purple"))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(.sRGB, red: 247/255, green: 245/255, blue: 248/255))
            .cornerRadius(10)
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("purple"), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}


extension DownloadPopupView {
    
    private func shareFile(_ url: URL) {
        let picker = NSSharingServicePicker(items: [url])
        if let window = NSApp.keyWindow, let contentView = window.contentView {
            picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
    }
    
    private func saveToUserLocation(_ fileURL: URL) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileURL.lastPathComponent
        panel.title = "Save SVG File"
        panel.canCreateDirectories = true
        
        panel.beginSheetModal(for: NSApp.keyWindow!) { response in
            guard response == .OK, let destinationURL = panel.url else { return }
            do {
                try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                print("✅ File saved to:", destinationURL.path)
            } catch {
                print("❌ Failed to save:", error)
            }
        }
    }
    
  private func regenerateSVG() {
    showLoader = true
    ApiManager.shared.generateSVGImage(
        prompt: prompt,
        style: "FLAT_VECTOR",
        image: selectedImage
    ) { result in
        DispatchQueue.main.async {
            showLoader = false
            switch result {
            case .success(let response):
                svgURL = response.svgURL
                imageURL = response.pngURL
            case .failure(let error):
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
}
