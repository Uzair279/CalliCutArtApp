import SwiftUI

struct DownloadPopupView: View {
    let imageURL: URL
    let hideScreen:() -> Void
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
                        SmallIconButton(systemName: "square.and.arrow.up")
                        SmallIconButton(systemName: "arrow.up.doc")
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
                        PurpleButton(icon: "arrow.down.circle", text: "Download")
                        PurpleButton(icon: "arrow.trianglehead.clockwise.rotate.90", text: "Regenrate")
                    }
                    
                    // Upgrade Button
                    Button(action: {}) {
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
        }
        .frame(width: 900, height: 453)
        .cornerRadius(16)
    }
}

struct PurpleButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        Button(action: {}) {
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


struct DownloadPopupView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadPopupView(imageURL: URL(fileURLWithPath: ""), hideScreen: {})
            .previewLayout(.sizeThatFits)
    }
}
