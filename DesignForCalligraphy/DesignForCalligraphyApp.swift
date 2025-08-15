
import SwiftUI

@main
struct DesignForCalligraphyApp: App {
    @StateObject var viewModel = SubscriptionViewModel()
    @State var isFirstTime: Bool = false
    var body: some Scene {
        WindowGroup {
            VStack {
                ContentView()
                    .environmentObject(viewModel)
                    .onAppear() {
                        let model = CoreDataManager.shared.fetchFirstTimeModel()
                        let isFirst =  model.first
                        isFirstTime = isFirst?.isFirsttime ?? true
                        if isFirst?.isFirsttime ?? true == true {
                            let newModel = IsFirstTime(isFirsttime: false)
                            CoreDataManager.shared.saveIsFirstTime(newModel)
                        }
                    }
            }
            .sheet(isPresented: $isFirstTime, content: {
                HowToUseView(showHowToUse: $isFirstTime)
            })
        }
    }
}
