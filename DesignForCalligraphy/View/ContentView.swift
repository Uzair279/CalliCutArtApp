import SwiftUI
struct ContentView: View {
    @StateObject var viewModel = CategoryViewModel()
    @Binding var screenType : screen 
    @State var svgURL : URL?
    var body: some View {
        switch screenType {
        case .home:
            HomeView(viewModel: viewModel, svgURL: $svgURL, screenType: $screenType)
        case .canvas:
            CanvasView(sideBarVM: viewModel, screenType: $screenType, svgURL: $svgURL)
                .frame(minWidth: 1200, minHeight: 750)
        }
   
    }
}


