
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
    @State var showResetAlert: Bool = false
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
                        .font(.custom(Fonts.bold.rawValue, size: 18))
                    Spacer()
                    HStack(spacing: 32) {
                        UndoManagerView(image: "undo", action: {
                            if sideBarVM.svgVM?.undoManager?.canUndo ?? false {
                                sideBarVM.svgVM?.undoManager?.undo()
                            }
                        })
                        UndoManagerView(image: "resetAll", action: {
                            sideBarVM.svgVM?.resetAll()
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
                            sideBarVM.svgVM?.selectedLayer = nil
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
                        LayersView(vm: sideBarVM, svgView: sideBarVM.svgVM!)
                    }
                    
                }
                .background(.white)
            }
//            .alert("Do you want to reset all?", isPresented: $showResetAlert) {
//                Button("No", role: .cancel) {}
//                Button("Yes", role: .destructive) {
//                    sideBarVM.svgVM?.resetAll()
//                }
//            }
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
            .sheet(isPresented: $textEditor) {
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Text("Add Text")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "multiply.circle")
                            .onTapGesture {
                                textEditor = false
                            }
                            .padding(.top, 5)
                    }
                    .padding(.top)
                    TextEditor(text: $textEditorText)
                        .frame(width: 280, height: 120)
                        .padding(12)
                        .background(Color(.grey))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

                    Button(action: {
                        if !textEditorText.isEmpty {
                            textEditor = false
                            sideBarVM.svgVM?.addTextLayer(textEditorText)
                        }
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(textEditorText.isEmpty ? Color.gray.opacity(0.4) : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .animation(.easeInOut(duration: 0.2), value: textEditorText)
                    }
                    .buttonStyle(.plain)
                    .disabled(textEditorText.isEmpty)

                    Spacer()
                }
                .onAppear() {
                    textEditorText = ""
                }
                .padding()
                .frame(width: 320, height: 240)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
                .padding()
            }


                

        }
    }
    func exportLayerToFile(
        layer: CALayer,
        format: fileType,
        resolution: resolution
    ) {
        let baseSize = layer.bounds.size
        let scaleFactor: CGFloat
        switch resolution {
        case .first: scaleFactor = 1024 / max(baseSize.width, baseSize.height)
        case .second: scaleFactor = 2048 / max(baseSize.width, baseSize.height)
        case .third: scaleFactor = 4096 / max(baseSize.width, baseSize.height)
        }

        let scaledSize = CGSize(width: baseSize.width * scaleFactor, height: baseSize.height * scaleFactor)

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ExportedDesign"
        panel.allowedFileTypes = [format == .jpg ? "jpg" : format == .pdf ? "pdf" : "png"]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let url = panel.url {
                if format == .pdf {
                    // Create PDF context
                    guard let consumer = CGDataConsumer(url: url as CFURL),
                          let pdfContext = CGContext(consumer: consumer, mediaBox: nil, nil) else {
                        print("Failed to create PDF context")
                        return
                    }

                    var mediaBox = CGRect(origin: .zero, size: scaledSize)
                    pdfContext.beginPage(mediaBox: &mediaBox)
                    pdfContext.saveGState()
                    pdfContext.scaleBy(x: scaleFactor, y: scaleFactor)
                    layer.render(in: pdfContext)
                    pdfContext.restoreGState()
                    pdfContext.endPage()
                    pdfContext.closePDF()
                    print("Exported PDF successfully to \(url.path)")
                } else {
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

                    let imageData: Data?
                    switch format {
                    case .png:
                        imageData = bitmapRep?.representation(using: .png, properties: [:])
                    case .jpg:
                        imageData = bitmapRep?.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                    default:
                        imageData = nil
                    }

                    if let data = imageData {
                        do {
                            try data.write(to: url)
                            showAlert(title: "Export Successful", message: "File saved to:\n\(url.path)")
                        } catch {
                            showAlert(title: "Export Failed", message: error.localizedDescription, style: .warning)
                        }
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
    @ObservedObject var vm: CategoryViewModel
        @ObservedObject var svgView: SVGCanvasNSView

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image("layerIcon")
                Text("Layers")
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.bold.rawValue, size: 16))
                Spacer()
            }
            .padding(.leading, 10)

            ScrollView {
                VStack {
                    ForEach(Array(svgView.sublayers.enumerated()), id: \.element) { index, layer in
                        ListItem(
                            vm: vm,
                            title: "Layer \(index + 1)",
                            thumbnail: layer.snapshotImage(size: CGSize(width: 30, height: 30)),
                            layer: layer
                        )
                    }

                    if (vm.svgVM?.sublayers.isEmpty ?? true) {
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


