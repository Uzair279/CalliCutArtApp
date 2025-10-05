
import SwiftUI

struct AISVGGeneratorView : View {
    @State var showSaveSheet: Bool = false
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
           
        
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("purple"))
                .frame(width: 1066, height: 156)
                .overlay {
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
                    
                    .foregroundStyle(Color.white)
                    
                }
           
//            Spacer()
            PromptInputCard() {
                showSaveSheet = true
            }
            //Spacer()
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
                    DownloadPopupView() {
                        showSaveSheet = false
                    }
                }
            }
        }
        
    }
}
