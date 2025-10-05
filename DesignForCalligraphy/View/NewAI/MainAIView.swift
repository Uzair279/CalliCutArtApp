import SwiftUI

struct MainAIView: View {
    @Binding var screenType: SidebarItemType
    @Binding var screenType1: screen
    let historyAction: () -> Void
    var body: some View {
        VStack {
            switch screenType {
            case .aiSVGGenerator:
                AISVGGeneratorView()
            case .explore:
                ContentView(screenType: $screenType1)
            case .aiTShirtGenerator:
                AITShirtGeneratorView()
            case .aiFontFinder:
                AIFontFinderView()
            case .rateUs:
                EmptyView()
            case .support:
                EmptyView()
            }
        }
        .background(Color(.sRGB, red: 251/255, green: 251/255, blue: 251/255, opacity: 1.0))
    }
}


