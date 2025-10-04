import SwiftUI

struct SubSidemenu: View {
    let subcategories: [SubCategory]
    @Binding var selectedSubcategoryID: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(subcategories) { subcategory in
                    if let title = subcategory.title {
                        SidemenuItem(
                            text: title,
                            isSelected: selectedSubcategoryID == subcategory.id
                        )
                        .onTapGesture {
                            selectedSubcategoryID = subcategory.id
                        }
                    }
                }
            }
            
        }
        .padding()
        
    }
}
struct SidemenuItem: View {
    let text: String
    let isSelected: Bool
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .foregroundStyle(.black)
                .font(.custom(Fonts.regular.rawValue, size: 14))
            Spacer()
        }
        
        .frame(width: 160, height: 39)
        .background(Color.white)
        .cornerRadius(8.0)
        .overlay(
            RoundedRectangle(cornerRadius: 8.0)
                .strokeBorder(isSelected ? Color("purple") : Color("grey"), lineWidth: 1.75)
        )
    }
}
