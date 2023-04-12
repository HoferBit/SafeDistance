import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraController = CameraController()
    
    var body: some View {
        VStack {
            Text("Safe Distance")
                .font(.largeTitle)
                .padding()
            
            Text(cameraController.isPlaying ? "Playing" : "Paused")
                            .font(.title)
                            .padding()

                        Text(cameraController.distanceInfo)
                            .font(.body)
                            .padding()
                            .multilineTextAlignment(.center)
            
            // Add buttons to start and stop the capture session
            HStack {
                Button(action: {
                    cameraController.startSession()
                }) {
                    Text("Start Session")
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button(action: {
                    cameraController.stopSession()
                }) {
                    Text("Stop Session")
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            
            // Add more UI components as needed
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
