import SwiftUI
struct ContentView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State var screenType : screen = .home
    @State var svgURL : URL?
    var body: some View {
        switch screenType {
        case .home:
            HomeView(viewModel: viewModel, svgURL: $svgURL, screenType: $screenType)
                .frame(minWidth: 1300, minHeight: 750)
        case .canvas:
            CanvasView(sideBarVM: viewModel, screenType: $screenType, svgURL: $svgURL)
        }
   
    }
}


