
import SwiftUI

struct CanvasView: View {
    @StateObject var sideBarVM : CategoryViewModel
    @Binding var screenType : screen
    @Binding var svgURL : URL?
    var body: some View {
        VStack {
            TopBarView(sideBarVM: sideBarVM, svgURL: $svgURL){
                screenType = .home
            }
        }
    }
}

struct TopBarView: View {
    @StateObject var sideBarVM : CategoryViewModel
    @State var textEditor: Bool = false
    @State var textEditorText: String = ""
    @Binding var svgURL : URL?
    let backAction: () -> Void
    var body: some View {
        ZStack {
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
                            if sideBarVM.svgVM?.undoManager?.canUndo ?? false {
                                sideBarVM.svgVM?.undoManager?.undo()
                            }
                        })
                        UndoManagerView(image: "resetAll", action: {
                            sideBarVM.svgVM?.undoManager?.removeAllActions()
                        })
                        UndoManagerView(image: "redo", action: {
                            if sideBarVM.svgVM?.undoManager?.canRedo ?? false {
                                sideBarVM.svgVM?.undoManager?.redo()
                            }
                        })
                    }
                    Spacer()
                    HStack (spacing: 20) {
                        ImportExportView(text: "Import", textColor: .black, bgColor: "grey", action: {
                            sideBarVM.svgVM?.addImageLayerFromFinder()
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
                    CanvasSidemenu(showTextEditor: $textEditor)
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
                            SVGCanvasView(svgURL: svgPath, onCreateView: { view in
                                DispatchQueue.main.async {
                                    sideBarVM.svgVM = view
                                }
                            })
                            .frame(width: 500, height: 400)
                            .clipped()
                            
                        } else {
                            Text("No SVG selected")
                                .foregroundColor(.gray)
                                .frame(width: 400, height: 400)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Spacer()
                    if sideBarVM.svgVM != nil {
                        LayersView(vm: sideBarVM)
                    }
                    
                }
                .background(.white)
            }
            
            if textEditor {
                VStack(spacing: 8) {
                    TextEditor(text: $textEditorText)
                        .frame(width: 250, height: 100)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                    Button("Done") {
                        sideBarVM.svgVM?.addTextLayer(textEditorText)
                        textEditor = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
               
            }

        }
    }
}
struct CanvasSidemenu: View {
    @Binding  var showTextEditor: Bool
    var body: some View {
        VStack(spacing: 20) {
            CanvasSidemenuItem(image: "Text", text: "Text", action: {
                showTextEditor = true
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
    @StateObject var vm: CategoryViewModel
    @State var layerItems: [LayerItem] = []

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
                            vm: vm,
                            title: item.title,
                            isEyeSelected: $item.isEyeSelected,
                            isLockSelected: $item.isLockSelected,
                            listItem: $layerItems,
                            thumbnail: item.layer.snapshotImage(size: CGSize(width: 30, height: 30)),
                            layer: item.layer
                        )
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .frame(width: 289)

        .onAppear {
            generateLayerItems()
        }
        .onChange(of: vm.svgVM?.svgRootLayer?.sublayers?.first?.sublayers?.count) { _ in
            generateLayerItems()
        }
    }

    func generateLayerItems() {
         let sublayers = vm.svgSublayers
        layerItems = sublayers.enumerated().map { index, layer in
            LayerItem(
                layer: layer,
                title: "Layer \(index + 1)",
                isEyeSelected: false,
                isLockSelected: false
            )
        }
    }
}

