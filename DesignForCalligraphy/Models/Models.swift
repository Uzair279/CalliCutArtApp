import SwiftUI
import Foundation
struct SidebarMenuItem: Identifiable, Decodable {
    let id: Int
    let name: String // Icon name and label
    var isSelected: Bool
}


struct Category: Identifiable, Codable {
    let id: String? // Category ID
    let title: String? // Category title
    let subcategories: [SubCategory]? // Optional list of subcategories
}

struct SubCategory: Identifiable, Codable {
    let id: String? // Subcategory ID
    let title: String? // Subcategory title
    let itemCount: Int? // Optional list of items
}

struct Item: Identifiable {
    let id: String
    let title: String
}
struct LayerItem: Identifiable {
    let id = UUID()
    var title: String
    var isEyeSelected: Bool
    var isLockSelected: Bool
    var isDeleteSelected: Bool
}
