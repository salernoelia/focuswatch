//
//  WritingMotionManager.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 29.08.2024.

import CoreMotion
import Foundation

// MARK: - WritingMotionManager Class
/// A wrapper around `CMWritingMotionManager` to simplify starting and stopping accelerometer updates
/// and storing the data in a thread-safe ring buffer.
class WritingMotionManager {
  // MARK: - Properties

  /// The underlying `CMWritingMotionManager` instance that provides the sensor data.
  let WritingMotionManager = CMMotionManager()

  /// The fixed size of the data buffer.
  let bufferSize = 100

  /// A thread-safe ring buffer to store the most recent accelerometer data points.
  var dataBuffer = RingBuffer<CMAccelerometerData>(capacity: 100)

  // MARK: - Public Methods

  /// Starts collecting accelerometer data at a specified interval.
  /// - Parameter updateInterval: The time interval in seconds between accelerometer updates. Defaults to 0.01 (100 Hz).
  func startAccelerometerUpdates(updateInterval: TimeInterval = 0.01) {
    guard WritingMotionManager.isAccelerometerAvailable else { return }

    WritingMotionManager.accelerometerUpdateInterval = updateInterval
    WritingMotionManager.startAccelerometerUpdates(to: OperationQueue()) {
      [weak self] (data, error) in
      guard let self = self, error == nil, let data = data else { return }

      // Append the new data point to the ring buffer.
      self.dataBuffer.append(data)
    }
  }

  /// Stops the collection of accelerometer data.
  func stopAccelerometerUpdates() {
    WritingMotionManager.stopAccelerometerUpdates()
  }
}

