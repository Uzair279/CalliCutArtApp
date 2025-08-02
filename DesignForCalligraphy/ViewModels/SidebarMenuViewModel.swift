import SwiftUI
import Foundation
import CoreText
class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var svgVM: SVGCanvasNSView?
    init() {
        loadCategories()
        installFonts()
    }
    func installFonts() {
        registerFont(withName: "SF-Pro-Text-Bold", fileExtension: "otf")
        registerFont(withName: "SF-Pro-Text-Regular", fileExtension: "otf")
        registerFont(withName: "SF-Pro-Text-Medium", fileExtension: "otf")
    }

    func registerFont(withName name: String, fileExtension: String) {
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            print("Font file \(name).\(fileExtension) not found in bundle.")
            return
        }
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
        
        if success {
            print("Successfully registered font: \(name)")
        } else if let error = error?.takeUnretainedValue() {
            print("Error registering font: \(error.localizedDescription)")
        }
    }
    
    private func loadCategories() {
        // Load the JSON file
        guard let url = Bundle.main.url(forResource: "categories", withExtension: "json") else {
            print("JSON file not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedCategories = try JSONDecoder().decode([Category].self, from: data)
            DispatchQueue.main.async {
                self.categories = decodedCategories
            }
        } catch {
            print("Failed to decode JSON: \(error.localizedDescription)")
        }
    }
}
