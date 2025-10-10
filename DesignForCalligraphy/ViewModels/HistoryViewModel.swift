import Foundation

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
                .compactMap { url in
                    let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                    let date = attributes?[.modificationDate] as? Date ?? Date()
                    return SVGHistoryItem(name: url.lastPathComponent, date: date, fileURL: url)
                }
                .sorted(by: { $0.date > $1.date })
            
        } catch {
            print("❌ Error loading AISvgs folder:", error)
        }
    }
    
    func delete(_ item: SVGHistoryItem) {
        do {
            try FileManager.default.removeItem(at: item.fileURL)
            items.removeAll { $0.id == item.id }
        } catch {
            print("❌ Delete failed:", error)
        }
    }
}

