import SwiftUI

struct UndoManagerView: View {
    let image : String
    let action: () -> Void
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(image)
                .foregroundStyle(.black)
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
    var isselected : Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack (spacing: 6) {
                Image(image)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(isselected ? Color.white : .black)
                    .background(isselected ?Color("selectedColor") : .grey)
                    .cornerRadius(4)
                Text(text)
                    .foregroundStyle(isselected ? Color("selectedColor") : .black)
                    .font(.custom("", size: 14))
                
            }
        }
        .buttonStyle(.plain)
    }
}
struct ListItem: View {
    @State var vm: CategoryViewModel
    let title: String
    var thumbnail: NSImage?
    var layer: CALayer

    @State private var isEyeSelected: Bool = false
    @State private var isLockSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Image("layerBg")
                if let nsImage = thumbnail {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image("dots")
                }
            }

            Spacer()

            HStack(spacing: 9.03) {
                Button(action: {
                    if layer.isLocked {
                        showAlert(title: "Error", message: "Layer is Locked")
                    }
                    else  {
                        isEyeSelected.toggle()
                        vm.svgVM?.toggleLayerVisibility(layer)
                    }
                }) {
                    Image("eye")
                        .foregroundStyle(isEyeSelected ? .white : .black)
                        .frame(width: 21.66, height: 21.66)
                        .background(isEyeSelected ? Color("selectedColor") : Color("grey"))
                        .cornerRadius(1.77)
                }
                .buttonStyle(.plain)

                Button(action: {
                    isLockSelected.toggle()
                    vm.svgVM?.toggleLayerLock(layer)
                }) {
                    Image("lock")
                        .foregroundStyle(isLockSelected ? .white : .black)
                        .frame(width: 21.66, height: 21.66)
                        .background(isLockSelected ? Color("selectedColor") : Color("grey"))
                        .cornerRadius(1.77)
                }
                .buttonStyle(.plain)

                Button(action: {
                    if layer.isLocked {
                        showAlert(title: "Error", message: "Layer is Locked")
                    }
                    else  {
                        vm.svgVM?.deleteLayer(layer)
                    }
                }) {
                    Image("delete")
                        .frame(width: 21.66, height: 21.66)
                        .background(Color("grey"))
                        .cornerRadius(1.77)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 11)
        .frame(width: 269, height: 67)
        .background(Color("screenBg"))
        .border(vm.svgVM?.selectedLayer == layer ? Color.blue : .clear, width: 1)
        .onAppear {
            isEyeSelected = layer.isHidden
            isLockSelected = layer.name == "locked"
        }
    }
}


