
import SwiftUI

struct CanvasView: View {
    @Binding var screenType : screen
    @Binding var svgURL : URL?
    var body: some View {
        VStack {
            TopBarView(svgURL: $svgURL){
                screenType = .home
            }
        }
    }
}

struct TopBarView: View {
    @Binding var svgURL : URL?
    let backAction: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: {
                    backAction()
                }) {
                    Image("backArrow")
                }
                .buttonStyle(.plain)
                Text("Canvas")
                    .foregroundStyle(.black)
                    .font(.custom("Bold", size: 18))
                Spacer()
                HStack(spacing: 32) {
                    UndoManagerView(image: "undo", action: {
                        //Add action
                    })
                    UndoManagerView(image: "resetAll", action: {
                        //Add action
                    })
                    UndoManagerView(image: "redo", action: {
                        //Add action
                    })
                }
                Spacer()
                HStack (spacing: 20) {
                    ImportExportView(text: "Import", textColor: .black, bgColor: "grey", action: {
                        //Add import action
                    })
                    ImportExportView(text: "Export", textColor: .white, bgColor: "selectedColor", action: {
                        //Add Export action
                    })
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 64)
            .background(Color("screenBg"))
            HStack {
                CanvasSidemenu()
                    .frame(width: 120)
                    .background(.white)
                Divider()
                    .frame(width: 1)
                Spacer()
                ZStack {
                    // Fixed Background Image
                    Image("canvas")
                        .resizable()
                        .scaledToFit() // Ensures the image doesn't stretch
                        .frame(width: 500, height: 500) // Fixed size for consistency
                        .clipped()
                    
                    // SVG Layer
                    if let svgPath = svgURL {
                        SVGView(svgURL: svgPath, size: CGSize(width: 400, height: 400)) // SVG fixed size
                            .frame(width: 400, height: 400)
                            .clipped()
                    } else {
                        Text("No SVG selected")
                            .foregroundColor(.gray)
                            .frame(width: 400, height: 400)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                Spacer()
                LayersView()
                    
            }
            .background(.white)
        }
    }
}
struct CanvasSidemenu: View {
    var body: some View {
        VStack(spacing: 20) {
            CanvasSidemenuItem(image: "Text", text: "Text", action: {
               //Add action
            })
            CanvasSidemenuItem(image: "Image", text: "Image", action: {
               //Add action
            })
            CanvasSidemenuItem(image: "Neons", text: "Neons", action: {
               //Add action
            })
            CanvasSidemenuItem(image: "Designs", text: "Designs", action: {
               //Add action
            })
            CanvasSidemenuItem(image: "Calligraphy", text: "Caligraphy", action: {
               //Add action
            })
            CanvasSidemenuItem(image: "Backgrounds", text: "Backgrounds", action: {
               //Add action
            })
            Spacer()
        }
        .padding(.vertical, 20)
        
    }
}
struct LayersView: View {
    @State private var layerItems: [LayerItem] = [
        LayerItem(title: "Layer 1", isEyeSelected: true, isLockSelected: false, isDeleteSelected: false),
        LayerItem(title: "Layer 2", isEyeSelected: false, isLockSelected: true, isDeleteSelected: false),
        LayerItem(title: "Layer 3", isEyeSelected: false, isLockSelected: false, isDeleteSelected: true)
    ]

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image("layerIcon")
                Text("Layers")
                    .foregroundStyle(.black)
                    .font(.custom("Bold", size: 16))
                Spacer()
            }
            .padding(.leading, 10)
            ScrollView {
                VStack {
                    ForEach($layerItems) { $item in
                        ListItem(
                            title: item.title,
                            isEyeSelected: $item.isEyeSelected,
                            isLockSelected: $item.isLockSelected,
                            isDeleteSelected: $item.isDeleteSelected
                        )
                    }
                }
               
            }
        }
        .padding(.vertical, 20)
        .frame(width: 289)
    }
}
