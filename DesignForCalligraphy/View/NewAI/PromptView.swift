import SwiftUI

struct PromptInputCard: View {
    @EnvironmentObject var premiumVM : SubscriptionViewModel
    @Binding var promptText: String
    @StateObject private var speechManager = SpeechManager()
    @State private var showSettingsAlert = false
    @Binding var selectedImage: NSImage?
    @Binding var selectedStyle : String
   
    let styleOptions = [
        "FLAT_VECTOR", "FLAT_VECTOR_OUTLINE", "FLAT_VECTOR_SILHOUETTE", "FLAT_VECTOR_ONE_LINE_ART", "FLAT_VECTOR_LINE_ART"
    ]
    let generateAction: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {

                ClearTextEditor(text: $promptText)
                    .disabled(speechManager.isRecording)
                    .frame(minHeight: 35, maxHeight: 100)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        // Placeholder
                        Group {
                            if promptText.isEmpty  {
                                Text("Type your idea here in English...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .font(.system(size: 14))
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )
                    .onChange(of: speechManager.transcript) { newValue in
                        promptText = newValue
                    }
                HStack {
                    if let selectedImage = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: selectedImage)
                                .resizable()
                                .frame(width: 45, height: 45)
                                .cornerRadius(6)
                            Button(action: {
                                withAnimation {
                                    self.selectedImage = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .offset(x: 6, y: -6)
                        }
                    }
                    
                    Spacer()
                }

                HStack(spacing: 12) {
                    Button(action: { openImageFromFinder() }) {
                        Image(systemName: "camera")
                            .foregroundColor(Color("purple"))
                            .font(.system(size: 18))
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .cornerRadius(100)
                            .overlay {
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color.gray, lineWidth: 1)
                            }
                        
                    }
                    .buttonStyle(.plain)
                    Button(action: handleMicTapped) {
                        Image(systemName: speechManager.isRecording ? "mic.fill" : "mic")
                            .foregroundColor(speechManager.isRecording ? .red : Color("purple"))
                            .font(.system(size: 18))
                            .frame(width: 48, height: 48)
                            .background(Color.white)
                            .cornerRadius(100)
                            .overlay {
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color.gray, lineWidth: 1)
                            }
                            
                    }.buttonStyle(.plain)

                    // Dropdown Buttons
                    DropdownTagView(label: "Style",
                                    options: styleOptions,
                                    selectedOption: $selectedStyle)


                    Spacer()

                    Button(action: { generateAction() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text("Generate")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color("purple"))
                        .cornerRadius(8)
                    }
                    .disabled(promptText.isEmpty)
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )

            // MARK: "1/2" Badge
            let current = CoreDataManager.shared.getCurrentPageCount()
            HStack(spacing: 0) {
                Text("\(current)/")
                    .foregroundColor(.white)
                if premiumVM.isProductPurchased || isProuctPro {
                    Image(systemName: "infinity")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(totalFreeGeneration)")
                        .foregroundColor(.white)
                }
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color("purple"))
            .cornerRadius(6)
            .offset(x: -12, y: -10)

        }
        .padding(.horizontal, 48)
        .padding(.vertical)
        .frame(width: 791, height: 184)
        .alert("Microphone Access Denied", isPresented: $showSettingsAlert) {
            Button("Open Settings") { openMacSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in System Settings → Privacy & Security → Microphone.")
        }
    }

    private func handleMicTapped() {
        if speechManager.isRecording {
            speechManager.stopRecording()
        } else {
            Task {
                let granted = await speechManager.requestPermission()
                if granted {
                    do { try speechManager.startRecording() }
                    catch { print("Error starting recording:", error) }
                } else {
                    showSettingsAlert = true
                }
            }
        }
    }

    private func openMacSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openImageFromFinder() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic"]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            if let url = panel.url, let image = NSImage(contentsOf: url) {
                self.selectedImage = image
            }
        }
    }
}


struct DropdownTagView: View {
    let label: String
    let options: [String]
    @Binding var selectedOption: String
    @State private var showPopover = false

    var body: some View {
        Button(action: {
            showPopover.toggle()
        }) {
            HStack(spacing: 4) {
                Text(selectedOption)
                    .font(.system(size: 13))
                    .foregroundColor(.black)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.top, 1)
            }
            .cornerRadius(100)
            .padding(.horizontal, 12)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selectedOption = option
                        showPopover = false
                    } label: {
                        HStack {
                            Text(option)
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                            Spacer()
                            if option == selectedOption {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    if option != options.last {
                        Divider()
                    }
                }
            }
            .cornerRadius(10)
            .padding(4)
        }
    }
}



struct ClearTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.isRichText = false
        textView.drawsBackground = false // <- key!
        textView.backgroundColor = .clear
        textView.textColor = .black
        textView.delegate = context.coordinator
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ClearTextEditor
        init(_ parent: ClearTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }
    }
}
