import SwiftUI

struct UndoManagerView: View {
    let image : String
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(image)
        }
        .buttonStyle(.plain)
    }
}
struct ImportExportView: View {
    let text: String
    let textColor: Color
    let bgColor : String
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(text)
                .foregroundStyle(textColor)
                .font(.custom("Medium", size: 16))
                .frame(width: 123, height: 42)
                .background(Color(bgColor))
                .cornerRadius(100)
        }
        .buttonStyle(.plain)
    }
}
struct CanvasSidemenuItem: View {
    let image : String
    let text : String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack (spacing: 6) {
                Image(image)
                    .frame(width: 32, height: 32)
                    .background(Color("grey"))
                    .cornerRadius(4)
                Text(text)
                    .foregroundStyle(.black)
                    .font(.custom("", size: 14))
            }
        }
        .buttonStyle(.plain)
    }
}
struct ListItem: View {
    let title: String
    @Binding var isEyeSelected: Bool
    @Binding var isLockSelected: Bool
    @Binding var isDeleteSelected: Bool
    
    var body: some View {
        HStack {
            Image("dots")
            ZStack {
                Image("layerBg")
                Text(title)
            }
            Spacer()
            HStack(spacing: 9.03) {
                // Eye Button
                Button(action: {
                    isEyeSelected.toggle()
                }) {
                    Image("eye")
                        .foregroundStyle(isEyeSelected ? .white : .black)
                        .frame(width: 21.66, height: 21.66)
                        .background(isEyeSelected ? Color("selectedColor") : Color("grey"))
                        .cornerRadius(1.77)
                }
                .buttonStyle(.plain)
                
                // Lock Button
                Button(action: {
                    isLockSelected.toggle()
                }) {
                    Image("lock")
                        .foregroundStyle(isLockSelected ? .white : .black)
                        .frame(width: 21.66, height: 21.66)
                        .background(isLockSelected ? Color("selectedColor") : Color("grey"))
                        .cornerRadius(1.77)
                }
                .buttonStyle(.plain)
                
                // Delete Button
                Button(action: {
                    isDeleteSelected.toggle()
                }) {
                    Image("delete")
                        .foregroundStyle(isDeleteSelected ? .white : .black)
                        .frame(width: 21.66, height: 21.66)
                        .background(isDeleteSelected ? Color("selectedColor") : Color("grey"))
                        .cornerRadius(1.77)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11)
        .frame(width: 269, height: 67)
        .background(Color("screenBg"))
        .cornerRadius(7.08)
    }
}
