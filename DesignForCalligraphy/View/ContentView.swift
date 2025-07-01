import SwiftUI
struct ContentView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State var screenType : screen = .home
    @State var svgURL : URL?
    var body: some View {
        switch screenType {
        case .home:
            HomeView(viewModel: viewModel, svgURL: $svgURL, screenType: $screenType)
        case .canvas:
            CanvasView(screenType: $screenType, svgURL: $svgURL)
        }
   
    }
}


