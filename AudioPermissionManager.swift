import AVFoundation
import Speech

class AudioPermissionManager {
    static let shared = AudioPermissionManager()

    // Request Microphone and Speech Recognition permissions
    func requestPermissions(completion: @escaping (Bool, Bool) -> Void) {
        requestMicrophonePermission { micGranted in
            self.requestSpeechRecognitionPermission { speechGranted in
                completion(micGranted, speechGranted)
            }
        }
    }

    // Request Microphone permission
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Microphone access granted.")
                    } else {
                        print("Microphone access denied.")
                    }
                    completion(granted)
                }
            }
        case .denied:
            print("Microphone access previously denied.")
            completion(false)
        case .granted:
            print("Microphone access already granted.")
            completion(true)
        @unknown default:
            fatalError("Unknown microphone permission state.")
        }
    }

    // Request Speech Recognition permission
    func requestSpeechRecognitionPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition access granted.")
                    completion(true)
                case .denied:
                    print("Speech recognition access denied.")
                    completion(false)
                case .restricted, .notDetermined:
                    print("Speech recognition access restricted or not determined.")
                    completion(false)
                @unknown default:
                    fatalError("Unknown speech recognition permission state.")
                }
            }
        }
    }
}
