import CoreMotion
import Foundation

class WritingMotionManager {
  let WritingMotionManager = CMMotionManager()
  let bufferSize = 50

  var dataBuffer = RingBuffer<CMAccelerometerData>(capacity: 50)

  func startAccelerometerUpdates(updateInterval: TimeInterval = 0.04) {
    guard WritingMotionManager.isAccelerometerAvailable else { return }

    WritingMotionManager.accelerometerUpdateInterval = updateInterval
    WritingMotionManager.startAccelerometerUpdates(to: OperationQueue()) {
      [weak self] (data, error) in
      guard let self = self, error == nil, let data = data else { return }

      self.dataBuffer.append(data)
    }
  }

  func stopAccelerometerUpdates() {
    WritingMotionManager.stopAccelerometerUpdates()
  }
}
