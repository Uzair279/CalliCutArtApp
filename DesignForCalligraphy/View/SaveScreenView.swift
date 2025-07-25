import SwiftUI

struct ExportTemplateView: View {
    @Binding var showSaveScreen : Bool
    @State var fileType: fileType = .png
    @State var resolutionType: resolution = .first
    let previewImage: NSImage?
    var onExport: ((fileType, resolution) -> Void)
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .frame(width: 914, height: 525)

            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    if let nsImage = previewImage {
                        Image(nsImage: nsImage)
                            .resizable()
                            .frame(width: 437, height: 437)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("border")))
                            .cornerRadius(20)
                    } else {
                        Color.gray
                            .frame(width: 437, height: 437)
                            .cornerRadius(20)
                            .overlay(Text("Preview unavailable").foregroundColor(.white))
                    }

                    VStack(alignment: .leading, spacing: 60) {
                        VStack(spacing: 20) {
                            HStack(spacing: 3) {
                                formatButton(title: ".jpg", selected: fileType == .jpg)
                                    .onTapGesture {
                                        fileType = .jpg
                                    }
                                formatButton(title: ".png", selected: fileType == .png)
                                    .onTapGesture {
                                        fileType = .png
                                    }
                                formatButton(title: "Transparent", selected: fileType == .transparent)
                                    .onTapGesture {
                                        fileType = .transparent
                                    }
                            }

                            HStack(spacing: 3) {
                                resolutionButton(title: "1024/1024", selected: resolutionType == .first)
                                    .onTapGesture {
                                        resolutionType = .first
                                    }
                                resolutionButton(title: "2048/2048", selected: resolutionType == .second)
                                    .onTapGesture {
                                        resolutionType = .second
                                    }
                                resolutionButton(title: "4096/4096", selected: resolutionType == .third)
                                    .onTapGesture {
                                        resolutionType = .third
                                    }
                            }
                        }

                        VStack(spacing: 20) {
                            exportButton(title: "Export", isPrimary: true)
                                .onTapGesture {
                                    onExport(fileType, resolutionType)
                                    showSaveScreen = false
                                }
                            exportButton(title: "Share", isPrimary: false)
                        }
                    }
                    .frame(width: 420)
                }
            }
            .frame(width: 877, height: 437)
            .padding(.top, -0.5)

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "xmark")
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color("screenBg"))
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                        .onTapGesture {
                            showSaveScreen = false
                        }
                }
                Spacer()
            }
        }
        .frame(width: 914, height: 525)
    }

    func formatButton(title: String, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(selected ? .white : .black)
            .frame(width: 136, height: 32)
            .background(selected ? Color("selectedColor") : Color("screenBg"))
            .cornerRadius(4)
    }

    func resolutionButton(title: String, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(selected ? .white : .black)
            .frame(width: 136, height: 32)
            .background(selected ? Color("selectedColor") : Color("screenBg"))
            .cornerRadius(4)
    }

    func exportButton(title: String, isPrimary: Bool) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isPrimary ? .white : .black)
            .frame(width: 420, height: 42)
            .background(isPrimary ? Color("selectedColor") : Color("screenBg"))
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(isPrimary ? Color("selectedColor") :Color("screenBg"), lineWidth: 1.75)
            )
    }
}


enum fileType {
  case png
    case jpg
    case transparent
}
enum resolution {
   case first
    case second
    case third
}
