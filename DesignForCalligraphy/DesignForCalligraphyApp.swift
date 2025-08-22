
import SwiftUI

@main
struct DesignForCalligraphyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
        .commands {
                  CommandGroup(replacing: .newItem) {}   // disables ⌘N (New Window)// 🔑 removes system Help menu
                  
                  CommandMenu("Support") {                 // your custom Help
                      Button("Rate Us") {
                          let appID = "1234567890" // replace with your App Store ID
                          if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review&mt=12") {
                              NSWorkspace.shared.open(url)
                          }
                      }
                      
                      Button("Contact Us") {
                          if let url = URL(string: "mailto:nawazishali7016@gmail.com?subject=Support%20Request&body=Hello%20Team,") {
                              NSWorkspace.shared.open(url)
                          }
                      }
                  }
              }
    }
}
