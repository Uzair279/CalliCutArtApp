
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
    @State private var selectedColor: Color = .white
    @State  var showEditType : EditSidemenu? = nil
    @State var selectedSize: CGFloat = 30
    @State var selectedFont: String = "SF Pro Text"
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
                            showResetAlert = true
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
                HStack(spacing: 0) {
                    CanvasSidemenu(showTextEditor: $showEditType)
                        .frame(width: 120)
                        .background(.white)
                    Divider()
                        .frame(width: 0.5)
                        .overlay(
                            Rectangle()
                                .fill(Color("grey"))
                        )
                    switch showEditType{
                    case .text:
                        TextEditView(selectedSize: $selectedSize, selectedFont: $selectedFont, selectedColor: $selectedColor, showTextView: $textEditor, sideBarVM: sideBarVM)
                    case .background:
                        VStack(alignment: .leading) {
                            ColorPicker("Background Color", selection: $selectedColor)
                                .foregroundStyle(.black)
                                .onChange(of: selectedColor) { newColor in
                                    sideBarVM.svgVM?.changeBackgroundColor(NSColor(newColor))
                                }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                        .frame(width: 190)
                    default:
                        TextEditView(selectedSize: $selectedSize, selectedFont: $selectedFont, selectedColor: $selectedColor, showTextView: $textEditor, sideBarVM: sideBarVM)
                    }
                    
                    Divider()
                        .frame(width: 0.5)
                        .overlay(
                            Rectangle()
                                .fill(Color("grey"))
                        )   
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
                                    sideBarVM.svgVM?.loadSVG(url: svgPath)
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
            .onReceive(NotificationCenter.default.publisher(for: .didUpdateSublayers)) { notification in
                if let editTypeString = notification.userInfo?["editType"] as? String {
                    if editTypeString == "background" {
                        showEditType = .background
                    } else if editTypeString == "text" {
                        showEditType = .background
                        showEditType = .text
                        if let textLayer = sideBarVM.svgVM?.selectedLayer as? CATextLayer {
                            // Update state so TextEditView shows correct settings
                            if let attributedString = textLayer.string as? NSAttributedString {
                                let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
                                
                                if let font = attributes[.font] as? NSFont {
                                    selectedFont = font.fontName
                                    selectedSize = font.pointSize
                                }
                            }

                        }
                       
                    }
                }
            }

            .alert("Do you want to reset all?", isPresented: $showResetAlert) {
                Button("No", role: .cancel) {}
                Button("Yes", role: .destructive) {
                    showResetAlert = false
                    sideBarVM.svgVM?.resetAll()
                }
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
                            showEditType = .background
                            showEditType = .text
                            sideBarVM.svgVM?.addTextLayer(textEditorText)
                        }
                    }) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(textEditorText.isEmpty ? Color.gray.opacity(0.4) : Color("selectedColor"))
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
    @Binding  var showTextEditor: EditSidemenu?
    @State var showHowToUse = false
    var body: some View {
        VStack(spacing: 20) {
            CanvasSidemenuItem(image: "Text", text: "Text", action: {
                showTextEditor = .text
            })
            CanvasSidemenuItem(image: "Backgrounds", text: "Backgrounds", action: {
                showTextEditor = .background
            })
            CanvasSidemenuItem(image: "Image", text: "Image", action: {
               //Add action
            })
            .opacity(0)
            CanvasSidemenuItem(image: "Neons", text: "Neons", action: {
               //Add action
            })
            .opacity(0)
            CanvasSidemenuItem(image: "Designs", text: "Designs", action: {
               //Add action
            })
            .opacity(0)
            CanvasSidemenuItem(image: "Calligraphy", text: "Caligraphy", action: {
               //Add action
            })
            .opacity(0)
            Spacer()
            HStack(spacing: 3.48) {
                ZStack {
                    Circle()
                        .fill(.black)
                        .frame(width: 13.52, height: 13.52)
                    Text("?")
                        .foregroundStyle(.white)
                        .font(.custom(Fonts.regular.rawValue, size: 9.96))
                }
                Text("How to use?")
                    .foregroundStyle(.black)
                    .font(.custom(Fonts.regular.rawValue, size: 14))
            }
            .onTapGesture {
                showHowToUse = true
            }
        }
        .padding(.vertical, 20)
        .sheet(isPresented: $showHowToUse, content: {
            HowToUseView(showHowToUse: $showHowToUse)
        })
        
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


struct TextEditView: View {
    @State private var showPopover = false
    @Binding var selectedSize: CGFloat
    
    let fontSizes: [CGFloat] = [8, 10, 12, 14, 16, 18, 24, 30, 36]
    @State private var isPopoverPresented = false
    @Binding var selectedFont: String
    
    // List of available fonts (you can customize this further)
    private var availableFonts: [String] {
        NSFontManager.shared.availableFontFamilies
    }
    @Binding var selectedColor: Color
    @Binding var showTextView: Bool
    var sideBarVM : CategoryViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Text options")
                .foregroundStyle(.black)
                .font(.custom(Fonts.bold.rawValue, size: 16))
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("selectedColor"))
                    .frame(width: 160, height: 37)
                Text("+Add Text")
                    .foregroundStyle(.white)
                    .font(.custom(Fonts.regular.rawValue, size: 14))
            }
            .onTapGesture {
                showTextView = true
            }
            Text("Font")
                .foregroundStyle(.black)
                .font(.custom(Fonts.regular.rawValue, size: 12))
            Button(action: {
                isPopoverPresented.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("screenBg"))
                        .frame(width: 161, height: 32)
                    HStack {
                        Text(selectedFont)
                            .foregroundStyle(.black)
                            .font(.custom(Fonts.regular.rawValue, size: 12))
                        Spacer()
                        Image("downArrow")
                    }
                    .padding(.horizontal, 12)
                }
                .frame(width: 161, height: 32)
            }
            .buttonStyle(.plain)
            .disabled(!(sideBarVM.svgVM?.selectedLayer is CATextLayer))
            .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(availableFonts, id: \.self) { font in
                            Text(font)
                                .font(.custom(font, size: 14))
                                .padding(.horizontal)
                                .onTapGesture {
                                    selectedFont = font
                                    isPopoverPresented = false
                                    sideBarVM.svgVM?.changeFontUsingAttributes(newFont: NSFont(name: font, size: selectedSize)!)
                                }
                        }
                    }
                    
                }
                .padding(.vertical)
                .frame(width: 200, height: 300)
            }
            Button(action: {
                showPopover.toggle()
            }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("screenBg"))
                    .frame(width: 161, height: 32)
                HStack {
                    Text("\(Int(selectedSize))")
                        .foregroundStyle(.black)
                        .font(.custom(Fonts.regular.rawValue, size: 12))
                    Spacer()
                    Image("downArrow")
                }
                .padding(.horizontal, 12)
            }
            .frame(width: 161, height: 32)
        }
        .buttonStyle(.plain)
        .disabled(!(sideBarVM.svgVM?.selectedLayer is CATextLayer))
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(fontSizes, id: \.self) { size in
                            Button(action: {
                                selectedSize = size
                                showPopover = false
                                sideBarVM.svgVM?.changeFontSizeAttribute(size)
                            }) {
                                Text("\(Int(size)) pt")
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
                .frame(width: 100)
            }
            ColorPicker("Color", selection: $selectedColor)
            .onChange(of: selectedColor) { newColor in
                    sideBarVM.svgVM?.changeTextColor(NSColor(newColor))
            }
            .disabled(!(sideBarVM.svgVM?.selectedLayer is CATextLayer))
            Spacer()
        }
        .padding(.vertical, 20)
        .frame(width: 190)
        .background(.white)

    }
}
