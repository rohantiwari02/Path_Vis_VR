import Speech
import AVFoundation

class SpeechRecognitionManager: NSObject, SFSpeechRecognizerDelegate {
    
    // Singleton instance
    static let shared = SpeechRecognitionManager()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override private init() {
        super.init()
        speechRecognizer?.delegate = self
    }

    // Start speech recognition
    func startSpeechRecognition(completion: @escaping (String?) -> Void) {
        // Ensure the recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer is not available")
            completion(nil)
            return
        }

        do {
            // Set up audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            guard let recognitionRequest = recognitionRequest else {
                fatalError("Unable to create recognition request")
            }

            recognitionRequest.shouldReportPartialResults = true

            // Prepare the audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
                self.recognitionRequest?.append(buffer)
            }

            // Start the audio engine
            audioEngine.prepare()
            try audioEngine.start()

            // Start the recognition task
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    print("Transcription: \(transcription)")
                    completion(transcription)
                } else if let error = error {
                    print("Error recognizing speech: \(error.localizedDescription)")
                    completion(nil)
                }
            }

        } catch {
            print("Audio engine could not start: \(error.localizedDescription)")
            completion(nil)
        }
    }

    // Stop speech recognition
    func stopSpeechRecognition() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }

    // Reset the recognition task
    func reset() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
