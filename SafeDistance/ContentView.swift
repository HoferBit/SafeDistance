import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraController = CameraController()
    //@ObservedObject var cameraController: CameraController
    
    var body: some View {
        VStack {
            Text("安全距离检测")
                .font(.largeTitle)
                .padding()
            
            VStack {
                        Text("拖动以设置合适的脸面积占比:")
                        Slider(value: $cameraController.minSafeDistance, in: 0.01...0.5, step: 0.01)
                            .padding()
                        Text("脸面积占比告警值: \(cameraController.minSafeDistance, specifier: "%.2f")")
                        // Add other interface elements here
                    }

                        Text(cameraController.distanceInfo)
                            .font(.body)
                            .padding()
                            .multilineTextAlignment(.center)
            
            // Add buttons to start and stop the capture session
            HStack {
                Button(action: {
                    cameraController.startSession()
                }) {
                    Text("开始检测")
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button(action: {
                    cameraController.stopSession()
                }) {
                    Text("结束检测")
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
