import SwiftUI
import AVFoundation
import Speech


final class SpeechManager: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    @Published var isRecording = false
    @Published var transcript = ""
    @Published var showPermissionAlert = false
    
    func requestPermission() async -> Bool {
        // Request Speech Recognition first
        let speechStatus = await SFSpeechRecognizer.requestAuthorizationAsync()
        
        // Request Microphone access explicitly
        let micGranted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
        
        let isAuthorized = (speechStatus == .authorized) && micGranted
        if !isAuthorized {
            DispatchQueue.main.async { self.showPermissionAlert = true }
        }
        return isAuthorized
    }

    
    func startRecording() throws {
        guard !audioEngine.isRunning else { return }
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        
        let inputNode = audioEngine.inputNode
        request.shouldReportPartialResults = true
        
        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    if !result.bestTranscription.formattedString.isEmpty {
                        self.transcript = result.bestTranscription.formattedString
                    }
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            [weak self] (buffer, _) in
            self?.request?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        DispatchQueue.main.async { self.isRecording = true }
    }
    
    func stopRecording() {
        request?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Delay cancelling recognition to let buffers flush
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
        }
        
        DispatchQueue.main.async { self.isRecording = false }
    }

}
extension SFSpeechRecognizer {
    static func requestAuthorizationAsync() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in continuation.resume(returning: status) }
        }
    }
}

