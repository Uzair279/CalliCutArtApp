import SwiftUI

struct CustomAlertModifier<AlertContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let alertContent: () -> AlertContent

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isPresented ? 2 : 0)
                .animation(.easeInOut(duration: 0.2), value: isPresented)
            
            if isPresented {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isPresented)
                        .onTapGesture {
                            withAnimation { isPresented = false }
                        }
                    
                    alertContent()
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: isPresented)
                }
            }
        }
    }
}

extension View {
    func customAlert<AlertContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> AlertContent
    ) -> some View {
        self.modifier(CustomAlertModifier(isPresented: isPresented, alertContent: content))
    }
}
struct NoInternetAlert: View {
    let dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text("No Internet Connection")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Please check your connection and try again.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Button(action: dismiss) {
                Text("OK")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 8)
                    .background(Color("purple"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 8)
        .frame(maxWidth: 300)
    }
}
