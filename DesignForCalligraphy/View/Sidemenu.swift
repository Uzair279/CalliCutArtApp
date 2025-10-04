import SwiftUI

struct Sidemenu: View {
    @EnvironmentObject var premiumVM: SubscriptionViewModel
    let categories: [Category]
    @Binding var selectedCategoryID: String?
    @Binding var showPremium : Bool
    @State var showSettingView: Bool = false
    var body: some View {
        
        VStack(spacing: 50) {
            if !isProuctPro {
                if !premiumVM.isProductPurchased {
                    Image("goToProImage")
                        .onTapGesture {
                            showPremium = true
                        }
                }
            }
            ScrollView {
                ForEach(categories) { category in
                    if let title = category.title {
                        SidebarItem(
                            iconAndLabel: title,
                            isSelected: selectedCategoryID == category.title
                        )
                        .onTapGesture {
                            selectedCategoryID = category.title
                        }
                    }
                }
                SidebarItem(iconAndLabel: "Settings", isSelected: false)
                    .onTapGesture {
                        showSettingView = true
                    }
            }
            .padding(.top, isProuctPro || premiumVM.isProductPurchased ? 20 : 0)
            Spacer()
        }
        .sheet(isPresented: $showSettingView) {
            // Present your SubscriptionView
            SettingView(hideSettings: $showSettingView, showPremium: $showPremium)
        }
        
    }
}
struct SidebarItem: View {
    let iconAndLabel: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(iconAndLabel)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(isSelected ? Color("purple") : Color.black)
            Text(iconAndLabel)
                .foregroundStyle(isSelected ? Color("purple") : Color.black)
                .font(.custom(Fonts.medium.rawValue, size: 16))
            Spacer()
        }
        .padding(.leading,14)
        .frame(width: 198, height: 42)
        .background(isSelected ? Color("selectionLight") : Color.clear)
        .cornerRadius(8)
    }
}
