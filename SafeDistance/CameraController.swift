import Foundation
import AVFoundation
import Vision

class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var sequenceHandler = VNSequenceRequestHandler()
    var audioPlayer: AVAudioPlayer?
    
    private var frameInterval: Int = 30
    private var currentFrame: Int = 0
    
    @Published var isPlaying: Bool = false
    @Published var distanceInfo: String = "Distance information will be displayed here"

    
    override init() {
        super.init()
        self.captureSession = AVCaptureSession()
    }
    
    func startSession() {
        // Configure the capture session
        captureSession?.sessionPreset = .high
        
        // Set up the camera input
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No front camera found")
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession?.canAddInput(cameraInput) == true {
                captureSession?.addInput(cameraInput)
            }
        } catch {
            print("Error adding camera input: \(error)")
            return
        }
        
        // Set up the video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession?.canAddOutput(videoOutput) == true {
            captureSession?.addOutput(videoOutput)
        }
        
        // Start the capture session
        prepareAudioPlayer()
        captureSession?.startRunning()
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Only perform detection and distance calculation at the specified frame interval
            if currentFrame == frameInterval {
                currentFrame = 0
            } else {
                currentFrame += 1
                return
            }
        
        // Convert the sample buffer to a pixel buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Create a face landmarks request
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { (request, error) in
            guard let results = request.results as? [VNFaceObservation] else {
                print("No face detected")
                return
            }
            
            
            for face in results {
                // Estimate the distance based on facial landmarks
                let safe = self.isDistanceSafe(face: face)

                // Update the playing status
                DispatchQueue.main.async {
                    self.isPlaying = safe
                }

                // Play or stop warning audio
                if safe {
                    self.audioPlayer?.stop()
                    self.audioPlayer?.currentTime = 0
                } else {
                    self.playWarningAudio()
                }
            }
        }
        
        // Perform the face landmarks request
        do {
            try sequenceHandler.perform([faceLandmarksRequest], on: pixelBuffer)
        } catch {
            print("Error performing face landmarks request: \(error)")
        }
    }

    private func isDistanceSafe(face: VNFaceObservation) -> Bool {
        // Set a minimum safe distance in pixels (adjust this value as needed)
        let minSafeDistance: CGFloat = 0.1

            // Calculate the face width and height
            let faceWidth = face.boundingBox.width
            let faceHeight = face.boundingBox.height

            // Calculate the area of the face
            let distance = faceWidth * faceHeight
            DispatchQueue.main.async {
                self.distanceInfo = String(format: "Calculated face area: %.4f", distance)
            }

            // Compare the calculated face area with the minimum safe distance
            if distance < minSafeDistance {
                return true
            } else {
                return false
            }
        
    
        }
    
    func prepareAudioPlayer() {
        if let audioFileURL = Bundle.main.url(forResource: "warning_audio", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error initializing audio player: \(error.localizedDescription)")
            }
        } else {
            print("Error locating audio file")
        }
    }

    
    func playWarningAudio() {
        audioPlayer?.volume = 1.0
        if audioPlayer?.isPlaying == false {
            audioPlayer?.play()
        }
    }

    }
