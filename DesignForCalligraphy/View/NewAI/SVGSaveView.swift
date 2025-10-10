import SwiftUI


struct SVGDetailsView: View {
    let hideScreen: () -> Void
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 40) {
                
                // MARK: - Left: SVG Image & Icons
                VStack(spacing: 24) {
                    Image("dummySVG") // Add image to Assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .background(Color.white)
                        .cornerRadius(24)

                    // Share + Upload icons
                    HStack(spacing: 20) {
                        SmallIconButton(systemName: "square.and.arrow.up") {
                            
                        }
                        SmallIconButton(systemName: "arrow.up.doc") {
                            
                        }
                    }
                }

                // MARK: - Right: Details
                VStack(alignment: .leading, spacing: 20) {
                    Text("SVG Details")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)

                    Text("An SVG image of a gun in an artistic way.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Text Prompt")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        //ScrollView {
                            Text("an svg of a gun with a flower.")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                                .padding(.top, 10)
//                        }
                            
                    }
                    .padding(.leading, 14)
                    .frame(width: 389, height: 92, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(10)
                    Spacer()
                    HStack(spacing: 16) {
                        PurpleOutlineButton1(icon: "arrow.down.to.line", text: "Download SVG")
                        PurpleOutlineButton1(icon: "doc.on.doc", text: "Copy")
                    }

                    Spacer()
                }
                .frame(maxHeight: .infinity)
                .padding(.top, 16)

                Spacer()
            }
            .padding(40)
            .background(Color("lightPurple"))
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
        .background(Color(.sRGB, red: 247/255, green: 245/255, blue: 248/255))
        .cornerRadius(16)
    }
}
struct PurpleOutlineButton1: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(Color("purple"))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("purple"), lineWidth: 1)
        )
    }
}
struct SmallIconButton: View {
    let systemName: String
    let action: () -> Void
    var body: some View {
        Button(action: {action()}) {
            Image("share")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .font(.system(size: 16))
                .foregroundColor(Color("purple"))
                .frame(width: 29.8, height: 29.8)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("purple"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
