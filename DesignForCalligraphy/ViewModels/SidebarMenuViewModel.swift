import SwiftUI
import Foundation
class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []

    init() {
        loadCategories()
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
