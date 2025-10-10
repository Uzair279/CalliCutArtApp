import SwiftUI

struct SVGHistoryView: View {
    @StateObject private var viewModel = SVGHistoryViewModel()
    let action: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: { action() }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
            }
            
            // List
            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(viewModel.items) { item in
                        HStack(spacing: 12) {
                            // Thumbnail Icon
                            
                            if let imageURL = item.imageURL,
                               let nsImage = NSImage(contentsOf: imageURL) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color("grey"))
                                        .frame(width: 52, height: 49.27)
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 33.21, height: 33.21)
                                        
                                }
                                .padding(.leading, 12)
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 52, height: 49.27)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 12)
                            }
                            
                            // Name and date
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .medium))
                                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Action Buttons
                            HStack(spacing: 16) {
                                Button {
                                    viewModel.saveSVGToUserLocation(item)
                                } label: {
                                    Image(systemName: "square.and.arrow.down")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                }

                                ShareButton(fileURL: item.fileURL)
                                Button {
                                    viewModel.delete(item)
                                } label: {
                                    Image(systemName: "trash")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.black)
                            .padding(.trailing, 12)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("grey"), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 800, height: 552)
        .background(Color(.sRGB, red: 247/255, green: 245/255, blue: 248/255))
        .cornerRadius(16)
    }
}
struct ShareButton: View {
    let fileURL: URL

    var body: some View {
        Button {
            shareFile(fileURL)
        } label: {
            Image(systemName: "square.and.arrow.up")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
    }

    private func shareFile(_ url: URL) {
        let picker = NSSharingServicePicker(items: [url])
        // Find the current NSView to attach the picker
        if let window = NSApp.keyWindow,
           let contentView = window.contentView {
            picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
    }
}
