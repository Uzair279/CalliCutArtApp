import Foundation
import AppKit
import UniformTypeIdentifiers


class SVGHistoryViewModel: ObservableObject {
    @Published var items: [SVGHistoryItem] = []
    
    init() {
        loadHistory()
    }
    
    func loadHistory() {
        do {
            let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            let folderURL = libraryURL.appendingPathComponent("AISvgs")
            
            guard FileManager.default.fileExists(atPath: folderURL.path) else { return }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey])
            
            items = fileURLs
                .filter { $0.pathExtension.lowercased() == "svg" }
                .compactMap { svgURL in
                    let attributes = try? FileManager.default.attributesOfItem(atPath: svgURL.path)
                    let date = attributes?[.modificationDate] as? Date ?? Date()
                    
                    // Extract matching PNG name based on shared ID
                    let baseName = svgURL.deletingPathExtension().lastPathComponent
                    let pngName = baseName.replacingOccurrences(of: "svg_", with: "image_") + ".png"
                    let pngURL = folderURL.appendingPathComponent(pngName)
                    
                    return SVGHistoryItem(
                        name: svgURL.lastPathComponent,
                        date: date,
                        fileURL: svgURL,
                        imageURL: FileManager.default.fileExists(atPath: pngURL.path) ? pngURL : nil
                    )
                }
                .sorted(by: { $0.date > $1.date })
            
        } catch {

        }
    }

    
    func delete(_ item: SVGHistoryItem) {
        do {
            // Remove SVG
            try FileManager.default.removeItem(at: item.fileURL)
            
            // Remove PNG (if exists)
            if let imageURL = item.imageURL, FileManager.default.fileExists(atPath: imageURL.path) {
                try FileManager.default.removeItem(at: imageURL)
            }
            
            // Update UI
            items.removeAll { $0.id == item.id }
        } catch {
        }
    }

}


extension SVGHistoryViewModel {
    func saveSVGToUserLocation(_ item: SVGHistoryItem) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.svg]
        panel.nameFieldStringValue = item.fileURL.lastPathComponent
        panel.canCreateDirectories = true
        panel.title = "Save SVG File"

        // Find the active window to attach the sheet
        if let window = NSApp.keyWindow ?? NSApp.mainWindow {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let destinationURL = panel.url else { return }
                do {
                    try FileManager.default.copyItem(at: item.fileURL, to: destinationURL)
                    print("✅ SVG saved to:", destinationURL.path)
                } catch {
                    print("❌ Failed to save SVG:", error)
                }
            }
        } else {
            // fallback if no window is active
            panel.begin { response in
                guard response == .OK, let destinationURL = panel.url else { return }
                do {
                    try FileManager.default.copyItem(at: item.fileURL, to: destinationURL)
                    print("✅ SVG saved to:", destinationURL.path)
                } catch {
                    print("❌ Failed to save SVG:", error)
                }
            }
        }
    }
}
