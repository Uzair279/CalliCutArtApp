
import SwiftUI

@main
struct DesignForCalligraphyApp: App {
    @StateObject var viewModel = SubscriptionViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
