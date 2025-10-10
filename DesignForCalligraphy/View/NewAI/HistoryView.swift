import SwiftUI

struct SVGHistoryView: View {
    @StateObject private var viewModel = SVGHistoryViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("History")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Button(action: { viewModel.loadHistory() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            // List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        HStack(spacing: 12) {
                            // Thumbnail Icon
                            Image(systemName: "doc.text.image")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(Color("purple"))
                                .padding(.leading, 8)
                            
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
                                    NSWorkspace.shared.open(item.fileURL)
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                }
                                Button {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(item.fileURL.path, forType: .string)
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                Button {
                                    viewModel.delete(item)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 700, height: 500)
    }
}
