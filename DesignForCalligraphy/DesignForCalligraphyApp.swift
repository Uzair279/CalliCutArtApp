
import SwiftUI

@main
struct DesignForCalligraphyApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var viewModel = SubscriptionViewModel()
    @State var isFirstTime: Bool = false
    var body: some Scene {
        WindowGroup {
            VStack {
                HomeViewNew()
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
//                  CommandGroup(replacing: .newItem) {}   // disables ⌘N (New Window)// 🔑 removes system Help menu
                  
                  CommandMenu("Support") {                 // your custom Help
                      Button("Rate Us") {
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
struct HomeViewNew: View {
    @State private var selectedItem: SidebarItemType = .aiSVGGenerator
    @State var showPremium : Bool = false
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                HStack(spacing: 8.5) {
                    Image("sidemenuTopIcon")
                    Text("AI SVG Generator")
                        .foregroundStyle(Color("textColor"))
                        .font(.system(size: 16, weight: .bold))
                }
                ScrollView {
                    ForEach(SidebarItemType.allCases.filter { $0.isSelectable }) { item in
                        SideItem(
                            imageName: item.iconName,
                            text: item.title,
                            isSelected: selectedItem == item
                        )
                        .onTapGesture {
                            selectedItem = item
                        }
                    }
                }
                .padding(.top, 28)
                Spacer()
                ForEach(SidebarItemType.allCases.filter { !$0.isSelectable }) { item in
                    SideItem(
                        imageName: item.iconName,
                        text: item.title,
                        isSelected: false
                    )
                    .onTapGesture {
                        if item.title == "Rate Us" {
                            if let url = URL(string: "https://apps.apple.com/app/id\(appID)?mt=12?action=write-review") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        else if item.title == "Support" {
                            if let url = URL(string: contactEmail) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
                
                Button(action: {
                    showPremium = true
                }) {
                    Image("premiumSideIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 196, height: 166)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 32)
            .padding(.bottom, 20)
            .frame(width: 247)
            .background(.white)
            .shadow(color: Color(.sRGB, red: 155, green: 155, blue: 155, opacity: 0.25), radius: 10.1, x: 4, y: 0)
            MainAIView(screenType: $selectedItem) {
                //MARK: History
            }
        }
        .sheet(isPresented: $showPremium) {
            SubscriptionView(showPremium: $showPremium)
        }
        
    }
}
struct SideItem : View {
    let imageName: String
    let text: String
    let isSelected: Bool
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding(.leading, 28)
            Text(text)
                .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                .foregroundStyle(Color("textColor"))
            Spacer()
            if isSelected {
                Rectangle()
                    .fill(Color(.sRGB, red: 151/255, green: 77/255, blue: 208/255, opacity: 1.0))
                    .frame(width: 3, height: 48)
            }
            
        }
        .frame(height: 48)
        .background(isSelected ? Color("newSelection") : .white)
    }
}
struct MainAIView: View {
    @Binding var screenType: SidebarItemType
    let historyAction: () -> Void
    var body: some View {
        VStack {
            switch screenType {
            case .aiSVGGenerator:
                AISVGGeneratorView()
            case .explore:
                ContentView()
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

