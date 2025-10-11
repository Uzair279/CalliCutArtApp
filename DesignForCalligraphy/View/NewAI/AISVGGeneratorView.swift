
import SwiftUI

struct AISVGGeneratorView : View {
    @EnvironmentObject var network: NetworkMonitor
    @EnvironmentObject var premiumVM : SubscriptionViewModel
    @State var showSaveSheet: Bool = false
    @State var promptText = ""
    @State var selectedIMG: NSImage?
    @State private var generatedImageURL: URL? = nil
    @State private var generatedSVGURL: URL? = nil
    @State var showLoader : Bool = false
    @State var showHistory: Bool = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State var showPremium : Bool = false
    @State var noInternet : Bool = false
    @State var selectedStyle = "FLAT_VECTOR"
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: {
                        showHistory = true
                    }) {
                        Image("historyIcon")
                            .padding(.trailing, 48)
                            .padding(.top, 22)
                    }.buttonStyle(.plain)
                }
                
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("purple"))
                    .frame(width: 1066, height: 156)
                    .overlay {
                        ZStack {
                            PolygonView()
                            VStack {
                                Text("Text prompt to SVG in less than 10 seconds")
                                    .font(.system(size: 42, weight: .semibold))
                                    .padding(.top,15)
                                    .frame(height: 63)
                                Text("Discover the power of AI with our free Text-to-SVG generator!\nConvert your text prompts into stunning SVG illustrations using our advanced AI technology.")
                                    .font(.system(size:16, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .frame(height: 48)
                            }
                        }
                        .foregroundStyle(Color.white)
                        
                    }
                PromptInputCard(promptText: $promptText, selectedImage: $selectedIMG, selectedStyle: $selectedStyle) {
                    if network.isConnected {
                        let currentCount = CoreDataManager.shared.getCurrentPageCount()
                        if  premiumVM.isProductPurchased || isProuctPro || currentCount < totalFreeGeneration {
                            showLoader = true
                            ApiManager.shared.generateSVGImage(
                                prompt: promptText,
                                style: selectedStyle,
                                image: selectedIMG
                            ) { result in
                                switch result {
                                case .success(let localURL):
                                    showLoader = false
                                    generatedImageURL = localURL.pngURL
                                    generatedSVGURL = localURL.svgURL
                                    showSaveSheet = true
                                    let manager = CoreDataManager.shared
                                    let current = manager.getCurrentPageCount()
                                    manager.updateOrCreatePageCount(newValue: current + 1)
                                case .failure(let error):
                                    showLoader = false
                                    errorMessage = error.localizedDescription
                                    showErrorAlert = true
                                }
                            }
                        }
                        else {
                            showPremium = true
                        }
                    }
                    else {
                        noInternet = true
                    }
                }
                Image("promptImagePreview")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 48)
                    .frame(height: 226)
                Spacer()
            }
            .padding(.top, 20)
            .background(Color(.sRGB, red: 251/255, green: 251/255, blue: 251/255, opacity: 1.0))
            .overlay {
                if showSaveSheet {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea(.all)
                        if let url = generatedImageURL, let svgURL = generatedSVGURL {
                        DownloadPopupView(svgURL: .constant(svgURL), imageURL: .constant(url), prompt: promptText, selectedImage: selectedIMG, selectedStyle: selectedStyle) {
                            showSaveSheet = false
                        }
                    }
                    }
                }
                if showHistory {
                    ZStack {
                        Color.black.opacity(0.25)
                            .ignoresSafeArea(.all)
                        SVGHistoryView() {
                            showHistory = false
                        }
                    }
                }
            }
            if showLoader {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPremium) {
            SubscriptionView(showPremium: $showPremium)
        }
        .customAlert(isPresented: $noInternet) {
            NoInternetAlert { noInternet = false }
        }
    }
}
