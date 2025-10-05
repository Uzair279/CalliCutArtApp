import SwiftUI


struct PromptInputCard: View {
    @State private var promptText: String = ""
    let generateAction: () -> Void
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {

                ClearTextEditor(text: $promptText)
                    .frame(minHeight: 80, maxHeight: 100)
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        // Placeholder
                        Group {
                            if promptText.isEmpty {
                                Text("Type your idea here in English...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .font(.system(size: 14))
                                    .allowsHitTesting(false)
                            }
                        }, alignment: .topLeading
                    )

                // MARK: Bottom Controls
                HStack(spacing: 12) {
                    // Icons
                    HStack(spacing: 12) {
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
                            

                        Image(systemName: "mic")
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

                    // Dropdown Buttons
                    DropdownTagView(label: "Style")
                    DropdownTagView(label: "Color Mode")
                    DropdownTagView(label: "Image Complexity")


                    Spacer()

                    // Generate Button
                    Button(action: {
                        generateAction()
                    }) {
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
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
//                    .overlay(content: {
//                        RoundedRectangle(cornerRadius: 16)
//                            .stroke(Color("purple"), lineWidth: 1)
//                    })
            )

            // MARK: "1/2" Badge
            Text("1/2")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color("purple"))
                .cornerRadius(6)
                .offset(x: -12, y: -10)
        }
        .padding(.horizontal, 48)
        .padding(.vertical)
        .frame(width: 791, height: 184)
    }
}


struct DropdownTagView: View {
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
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
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .stroke(Color.gray, lineWidth: 1)
        )
    
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
