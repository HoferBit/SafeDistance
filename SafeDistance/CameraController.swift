import Foundation
import AVFoundation
import Vision

class CameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var sequenceHandler = VNSequenceRequestHandler()
    var audioPlayer: AVAudioPlayer?
    
    private var frameInterval: Int = 50
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
        let minSafeDistance: CGFloat = 0.23

        // Calculate the distance between the eyes and mouth
        guard let leftEye = face.landmarks?.leftEye,
              let rightEye = face.landmarks?.rightEye,
              let mouth = face.landmarks?.innerLips else {
            return false
        }

        let leftEyePosition = leftEye.normalizedPoints[0]
        let rightEyePosition = rightEye.normalizedPoints[0]
        let mouthPosition = mouth.normalizedPoints[0]

        let eyeDistance = hypot(rightEyePosition.x - leftEyePosition.x, rightEyePosition.y - leftEyePosition.y)
        let mouthToEyeDistance = hypot(mouthPosition.x - leftEyePosition.x, mouthPosition.y - leftEyePosition.y)
        
        let distance = eyeDistance * mouthToEyeDistance
            DispatchQueue.main.async {
                self.distanceInfo = String(format: "Calculated distance: %.2f", distance)
            }
        
        // Compare the calculated distance with the minimum safe distance
                if eyeDistance * mouthToEyeDistance < minSafeDistance {
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
