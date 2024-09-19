/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that selects an image and makes a prediction using Vision and Core ML.
*/

import UIKit
import AVFoundation

class MainViewController: UIViewController {
    var firstRun = true

    /// A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
    let imagePredictor = ImagePredictor()

    /// The largest number of predictions the main view controller displays the user.
    let predictionsToShow = 2

    // MARK: Main storyboard outlets
    @IBOutlet weak var startupPrompts: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!

    // Request permissions for microphone and speech recognition when the view loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request Microphone and Speech Recognition permissions
        AudioPermissionManager.shared.requestPermissions { micGranted, speechGranted in
            if micGranted && speechGranted {
                print("All permissions granted. Ready to proceed.")
                // Proceed with functionality that requires both permissions
            } else {
                print("Permissions not fully granted. Handle restricted functionality.")
                // Handle permission denial gracefully, perhaps disabling certain features
            }
        }
    }
    
    // Button action to start/stop listening
    @IBAction func startListeningButtonPressed(_ sender: UIButton) {
        if isListening {
            SpeechRecognitionManager.shared.stopSpeechRecognition()
            startListeningButton.setTitle("Start Listening", for: .normal)
            isListening = false
            print("Stopped listening.")
        } else {
            SpeechRecognitionManager.shared.startSpeechRecognition { transcription in
                if let transcription = transcription {
                    print("Recognized speech: \(transcription)")
                } else {
                    print("Speech recognition failed.")
                }
            }
            startListeningButton.setTitle("Stop Listening", for: .normal)
            isListening = true
        }
    }
}

extension MainViewController {
    // MARK: Main storyboard actions
    @IBAction func singleTap() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            present(photoPicker, animated: false)
            return
        }

        present(cameraPicker, animated: false)
    }

    @IBAction func doubleTap() {
        present(photoPicker, animated: false)
    }
}

extension MainViewController {
    // MARK: Main storyboard updates
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }

    func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.predictionLabel.text = message
        }

        if firstRun {
            DispatchQueue.main.async {
                self.firstRun = false
                self.predictionLabel.superview?.isHidden = false
                self.startupPrompts.isHidden = true
            }
        }
    }

    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
        updatePredictionLabel("Making predictions for the photo...")

        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(photo)
        }
    }
}

extension MainViewController {
    // MARK: Image prediction methods
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)
        let predictionString = formattedPredictions.joined(separator: "\n")
        updatePredictionLabel(predictionString)
    }

    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }
            return "\(name) - \(prediction.confidencePercentage)%"
        }
        return topPredictions
    }
}
