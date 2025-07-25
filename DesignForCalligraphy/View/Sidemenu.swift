import SwiftUI

struct Sidemenu: View {
    let categories: [Category]
    @Binding var selectedCategoryID: String?
    @Binding var showPremium : Bool
    var body: some View {
        
        VStack(spacing: 50) {
            Image("goToProImage")
                .onTapGesture {
                    showPremium = true
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
            }
            Spacer()
        }
        
    }
}
struct SidebarItem: View {
    let iconAndLabel: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(iconAndLabel)
                .frame(width: 24, height: 24)
                .foregroundStyle(isSelected ? Color("selectedColor") : Color.black)
            Text(iconAndLabel)
                .foregroundStyle(isSelected ? Color("selectedColor") : Color.black)
                .font(.custom("Medium", size: 16))
            Spacer()
        }
        .padding(.leading,14)
        .frame(width: 198, height: 42)
        .background(isSelected ? Color("selectionLight") : Color.clear)
        .cornerRadius(8)
    }
}
