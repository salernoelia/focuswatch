import CoreML
import CoreMotion
import Foundation
import WatchKit

class ActivityPredictor {
  private var model: MultiClassifier?

  init() {
    do {
      model = try MultiClassifier(configuration: MLModelConfiguration())
    } catch {
      print("Error initializing model: \(error)")
    }
  }

  func predictActivity(from dataBuffer: [CMAccelerometerData]) -> (
    classLabel: Int64?, probabilities: [Int: String]
  ) {
    guard let model = model, !dataBuffer.isEmpty else {
      print("Model is not loaded or dataBuffer is empty")
      return (nil, [:])
    }

    let vectors = dataBuffer.map {
      AccelerometerVector(x: $0.acceleration.x, y: $0.acceleration.y, z: $0.acceleration.z)
    }
    let features = FeatureCalculator.calculateFeatures(for: vectors)

    do {
      let modelInput = convertToModelInput(features)
      let result = try model.prediction(input: modelInput)

      let totalProbability = result.classProbability.values.reduce(0, +)
      var normalizedPredictions = [Int: String]()
      for (key, value) in result.classProbability {
        let normalizedValue = value / totalProbability
        normalizedPredictions[Int(key)] = String(format: "%.2f", normalizedValue)
      }

      print("Model prediction prob:", normalizedPredictions)
      print("Model prediction class:", result.classLabel)
      return (result.classLabel, normalizedPredictions)
    } catch {
      print("Error making prediction: \(error)")
      return (nil, [:])
    }
  }

  func convertToModelInput(_ features: FeatureData) -> MultiClassifierInput {
    return MultiClassifierInput(
      mean_AccX: features.mean_AccX, mean_AccY: features.mean_AccY, mean_AccZ: features.mean_AccZ,
      std_AccX: features.std_AccX, std_AccY: features.std_AccY, std_AccZ: features.std_AccZ,
      median_AccX: features.median_AccX, median_AccY: features.median_AccY,
      median_AccZ: features.median_AccZ,
      abs_energy_AccX: features.abs_energy_AccX, abs_energy_AccY: features.abs_energy_AccY,
      abs_energy_AccZ: features.abs_energy_AccZ,
      skwness_AccX: features.skwness_AccX, skwness_AccY: features.skwness_AccY,
      skwness_AccZ: features.skwness_AccZ,
      emg_var_AccX: features.emg_var_AccX, emg_var_AccY: features.emg_var_AccY,
      emg_var_AccZ: features.emg_var_AccZ,
      mean_crossings_AccX: features.mean_crossings_AccX,
      mean_crossings_AccY: features.mean_crossings_AccY,
      mean_crossings_AccZ: features.mean_crossings_AccZ,
      waveform_length_AccX: features.waveform_length_AccX,
      waveform_length_AccY: features.waveform_length_AccY,
      waveform_length_AccZ: features.waveform_length_AccZ,
      percentile_15_AccX: features.percentile_15_AccX,
      percentile_15_AccY: features.percentile_15_AccY,
      percentile_15_AccZ: features.percentile_15_AccZ
    )
  }
}
