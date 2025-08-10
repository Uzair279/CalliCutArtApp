
import SwiftUI
import SDWebImageSwiftUI

struct HowToUseView: View {
    @State var useScreenType: UseScreenType = .click
    @Binding var showHowToUse: Bool
    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Spacer()
                Text("How to edit object into Art board?")
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.bold.rawValue, size: 20))
                Spacer()
                Image("crossNew")
                    .onTapGesture {
                        showHowToUse = false
                    }
            }
            .padding(.horizontal, 20)
            .frame(width: 914, height: 77)
            .background(Color("howtoUsetopColor"))
            switch useScreenType {
            case .click:
                Firstscreen(text: "First of all double tap on an object to make a selection \n then perform an action whatever you want.", image: "clickIcon", type: useScreenType)
                    .padding(.top, 10)
            case .zoom:
                Firstscreen(text: "Use Pinch Zoom In Out App Gesture for resizing object on our App.", image: "rotateIcon", type: useScreenType)
                    .padding(.top, 10)
            case .rotate:
                Firstscreen(text: "Move your fingers clock wise or anti clock wise for rotating an object.", image: "rotateIcon", type: useScreenType)
                    .padding(.top, 10)
            }
           Spacer()
            HStack {
                Circle()
                    .stroke(useScreenType == .click ? Color("selectedColor") : .clear, lineWidth: 1)
                    .background(Circle().fill(Color("selectedColor")).frame(width: 10, height: 10))
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        useScreenType = .click
                    }
                Circle()
                    .stroke(useScreenType == .zoom ? Color("selectedColor") : .clear, lineWidth: 1)
                    .background(Circle().fill(Color("selectedColor")).frame(width: 10, height: 10))
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        useScreenType = .zoom
                    }
                Circle()
                    .stroke(useScreenType == .rotate ? Color("selectedColor") : .clear, lineWidth: 1)
                    .background(Circle().fill(Color("selectedColor")).frame(width: 10, height: 10))
                    .frame(width: 20, height: 20)
                    .onTapGesture {
                        useScreenType = .rotate
                    }
            }
            .padding(.bottom, 27)
        }
        .frame(width: 914, height: 525)
        .background(.white)
    }
}

#Preview {
    HowToUseView(showHowToUse: .constant(false))
}
struct Firstscreen : View {
    let text: String
    let image : String
    let type: UseScreenType
    var body: some View {
        VStack {
            Text(text)
                .foregroundStyle(.black)
                .font(.custom(Fonts.regular.rawValue, size: 16))
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Spacer()
                VStack {
                    Image("circutBorder")
                        .rotationEffect(type == .rotate ? Angle(degrees: 24.45) : Angle(degrees: 0))
                    if type != .rotate {
                        Image("circut")
                    }
                }
                if type == .zoom {
                    if let path = Bundle.main.path(forResource: "zoom", ofType: "gif") {
                        let url = URL(fileURLWithPath: path)
                        AnimatedImage(url: url)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 338, height: 301) 
                    } else {
                        Image(image)
                    }
                }
                else {
                    Image(image)
                }
                Spacer()
            }
        }
    }
}
enum UseScreenType{
    case click
    case zoom
    case rotate
}
