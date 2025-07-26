
import SwiftUI
import AppKit
import SVGKit


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
    @State var showSaveScreen = false
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
                           showSaveScreen = true
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
            .sheet(isPresented: $showSaveScreen) {
                if let preview = sideBarVM.svgVM?.svgRootLayer?.snapshot() {
                    ExportTemplateView(showSaveScreen: $showSaveScreen, previewImage: preview) { selectedFormat, selectedResolution in
                        if let layer = sideBarVM.svgVM?.svgRootLayer {
                            exportLayerToFile(layer: layer, format: selectedFormat, resolution: selectedResolution)
                        }
                    }
                } else {
                    ExportTemplateView(showSaveScreen: $showSaveScreen, previewImage: nil) { selectedFormat, selectedResolution in
                        if let layer = sideBarVM.svgVM?.svgRootLayer {
                            exportLayerToFile(layer: layer, format: selectedFormat, resolution: selectedResolution)
                        }
                    }
                }
                
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
   
    func exportLayerToFile(
        layer: CALayer,
        format: fileType,
        resolution: resolution
    ) {
        // Determine size
        let baseSize = layer.bounds.size
        let scaleFactor: CGFloat
        switch resolution {
        case .first: scaleFactor = 1024 / max(baseSize.width, baseSize.height)
        case .second: scaleFactor = 2048 / max(baseSize.width, baseSize.height)
        case .third: scaleFactor = 4096 / max(baseSize.width, baseSize.height)
        }

        let scaledSize = CGSize(width: baseSize.width * scaleFactor, height: baseSize.height * scaleFactor)

        // Begin bitmap context
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(scaledSize.width),
            pixelsHigh: Int(scaledSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep!) else {
            print("Failed to create graphics context")
            return
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        context.cgContext.scaleBy(x: scaleFactor, y: scaleFactor)
        layer.render(in: context.cgContext)

        NSGraphicsContext.restoreGraphicsState()

        // Ask user where to save
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ExportedDesign"
        panel.allowedFileTypes = [format == .jpg ? "jpg" : "png"]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                let imageData: Data?
                switch format {
                case .png, .transparent:
                    imageData = bitmapRep?.representation(using: .png, properties: [:])
                case .jpg:
                    imageData = bitmapRep?.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                }

                if let data = imageData {
                    do {
                        try data.write(to: url)
                        print("Exported successfully to \(url.path)")
                    } catch {
                        print("Failed to save image: \(error)")
                    }
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
                    // Access the actual sublayers directly
                    if let layers = vm.svgVM?.svgRootLayer?.sublayers {
                        ForEach(Array(layers.enumerated()), id: \.element) { index, layer in
                            ListItem(
                                vm: vm,
                                title: "Layer \(index + 1)",
                                thumbnail: layer.snapshotImage(size: CGSize(width: 30, height: 30)),
                                layer: layer
                            )
                        }
                    }
                     else {
                        Text("No layers available")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .frame(width: 289)
    }
}


