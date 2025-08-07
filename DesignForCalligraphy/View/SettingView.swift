import SwiftUI

struct SettingView : View {
    @Binding var hideSettings: Bool
    @State var isDarkMode: Bool = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image("arrow")
                    .onTapGesture {
                        hideSettings = false
                    }
                Text("Settings")
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.bold.rawValue, size: 20))
                Spacer()
            }
            VStack(spacing: 15) {
                SettingItem(text: "Language", anotherText: "English")
                HStack {
                   Text("Dark Mode")
                        .foregroundStyle(.black)
                        .font(.custom(Fonts.regular.rawValue, size: 20))
                    Spacer()
                    Toggle("", isOn: $isDarkMode)
                        .toggleStyle(SwitchToggleStyle(tint: Color("selectedColor")))
                }
                .padding(.horizontal, 20)
                .frame(width: 734, height: 42)
                .background(.white)
                .cornerRadius(8)
                SettingItem(text: "Unlock Pro", anotherText: nil)
                SettingItem(text: "Restore purchase", anotherText: nil)
                SettingItem(text: "Contact us", anotherText: nil)
                SettingItem(text: "Rate app", anotherText: nil)
            }
            .padding(.top, 25)
        }
        .padding(.horizontal, 20)
        .frame(width: 774, height: 416)
        .background(Color("screenBg"))
    }
}
struct SettingItem : View {
    let text: String
    let anotherText: String?
    var body: some View {
        HStack {
           Text(text)
                .foregroundStyle(.black)
                .font(.custom(Fonts.regular.rawValue, size: 20))
            Spacer()
            if let anotherText {
                Text(anotherText)
                    .foregroundStyle(Color("premiumgrey"))
                    .font(.custom(Fonts.regular.rawValue, size: 16))
            }
        }
        .padding(.horizontal, 20)
        .frame(width: 734, height: 42)
        .background(.white)
        .cornerRadius(8)
    }
}
