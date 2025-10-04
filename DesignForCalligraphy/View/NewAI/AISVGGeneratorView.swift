
import SwiftUI

struct AISVGGeneratorView : View {
    @State var showSaveSheet: Bool = false
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("purple"))
                    .padding(.horizontal, 48)
                    .frame(height: 156)
                VStack {
                    Text("Text prompt to SVG in less than 10 seconds")
                        .font(.system(size: 42, weight: .semibold))
                    Text("Discover the power of AI with our free Text-to-SVG generator!\nConvert your text prompts into stunning SVG illustrations using our advanced AI technology.")
                        .font(.system(size:16, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                
                .foregroundStyle(Color.white)
                
            }
            .frame(width: 1066)
            Spacer()
            PromptInputCard() {
                showSaveSheet = true
            }
            Spacer()
            Image("promptImagePreview")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal, 48)
                .frame(height: 226)
        }
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
