import SwiftUI

struct AITShirtGeneratorView: View {
    @State var showSaveSheet : Bool = false
    let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 20)
    ]

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
                    VStack{
                        Text("Design a T-Shirt in minutes!")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top,15)
                            .frame(height: 63)
                        Text("Discover the power of AI with our free T-Shirt generator!\nConvert your text prompts into stunning T-Shirts using our advanced AI technology.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(height: 48)
                    }
                )

            // MARK: - Input Card
            PromptInputCard() {
                showSaveSheet = true
            }
            // MARK: - Generated T-shirts Grid
            VStack(alignment: .leading, spacing: 12) {
                Text("Find the perfect T-shirt")
                    .font(.system(size: 18, weight: .bold))
                    .padding(.leading, 48)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(0..<8) { index in
                            Image("dummyTshirt") // Name your images accordingly
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 180, height: 180)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 48)
                }
            }

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
