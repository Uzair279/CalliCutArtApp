import SwiftUI
import Foundation
struct SidebarMenuItem: Identifiable, Decodable {
    let id: Int
    let name: String // Icon name and label
    var isSelected: Bool
}


struct Category: Identifiable, Codable, Equatable {
    let id: String? // Category ID
    let title: String? // Category title
    let subcategories: [SubCategory]? // Optional list of subcategories
}

struct SubCategory: Identifiable, Codable, Equatable {
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
    var layer: CALayer
    var title: String
    var isEyeSelected: Bool
    var isLockSelected: Bool
}

class SVGLayerModel: NSObject, Identifiable {
    let id = UUID()
    var type: SVGElementType?
    var pathData: String?
    var text: String?

    var position: CGPoint = .zero
    var rotation: CGFloat = 0
    var scale: CGFloat = 1.0
}


struct UserSaveModel: Codable {
    var isPro: Bool
}
struct IsFirstTime: Codable {
    var isFirsttime: Bool
}
struct SidebarItemModel: Identifiable {
    let id = UUID()
    let type: SidebarItemType
}
struct GenerateImageRequest: Encodable {
    let prompt: String
    let negativePrompt: String
    let style: String?
    let initialImage: String?
    let initialImageType: String?
}
struct GenerateImageResponse: Decodable {
    let success: Bool
    let data: [GeneratedImage]
}

struct GeneratedImage: Decodable {
    let id: String
    let description: String
    let pngUrl: String
    let svgUrl: String
    let prompt: String
    let negativePrompt: String
    let style: String
}

struct SVGImageData: Decodable {
    let id: String
    let svgUrl: String?
    let pngUrl: String?
}


struct SVGHistoryItem: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let fileURL: URL
}
