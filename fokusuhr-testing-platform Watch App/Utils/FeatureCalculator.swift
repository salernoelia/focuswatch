import CoreML
import CoreMotion
import Foundation
import StatKit
import WatchKit

struct FeatureData: Codable {
  let mean_AccX, std_AccX, median_AccX, abs_energy_AccX, skwness_AccX, emg_var_AccX,
    mean_crossings_AccX, waveform_length_AccX, percentile_15_AccX: Double
  let mean_AccY, std_AccY, median_AccY, abs_energy_AccY, skwness_AccY, emg_var_AccY,
    mean_crossings_AccY, waveform_length_AccY, percentile_15_AccY: Double
  let mean_AccZ, std_AccZ, median_AccZ, abs_energy_AccZ, skwness_AccZ, emg_var_AccZ,
    mean_crossings_AccZ, waveform_length_AccZ, percentile_15_AccZ: Double
}

class FeatureCalculator {
  static func calculateFeatures(for dataBuffer: [AccelerometerVector]) -> FeatureData {
    //        let handedness = UserConfigs.shared.handedness
    //        let crownLocation = UserConfigs.shared.crownLocation

    // Adjust data based on handedness and crown location
    let adjustedDataBuffer = dataBuffer.map { vector -> AccelerometerVector in
      let adjustedX = vector.y  // transform to actigraph format
      let adjustedY = -vector.x  // transform to actigraph format
      let adjustedZ = vector.z
      //
      //            if handedness == .left {
      //                adjustedX = -adjustedX
      //            }
      //
      //            if crownLocation == .left {
      //                adjustedX = -adjustedX
      //                adjustedY = -adjustedY
      //            }

      return AccelerometerVector(x: adjustedX, y: adjustedY, z: adjustedZ)
    }

    // Calculate features
    let featureX = calculateAxisFeatures(for: adjustedDataBuffer.map { $0.x })
    let featureY = calculateAxisFeatures(for: adjustedDataBuffer.map { $0.y })
    let featureZ = calculateAxisFeatures(for: adjustedDataBuffer.map { $0.z })

    let bufferSize = 1200

    return FeatureData(
      mean_AccX: featureX.mean, std_AccX: featureX.std, median_AccX: featureX.median,
      abs_energy_AccX: featureX.absEnergy, skwness_AccX: featureX.skewness,
      emg_var_AccX: featureX.absEnergy / Double(bufferSize - 1),
      mean_crossings_AccX: featureX.meanCrossings, waveform_length_AccX: featureX.waveformLength,
      percentile_15_AccX: featureX.percentile15,
      mean_AccY: featureY.mean, std_AccY: featureY.std, median_AccY: featureY.median,
      abs_energy_AccY: featureY.absEnergy, skwness_AccY: featureY.skewness,
      emg_var_AccY: featureY.absEnergy / Double(bufferSize - 1),
      mean_crossings_AccY: featureY.meanCrossings, waveform_length_AccY: featureY.waveformLength,
      percentile_15_AccY: featureY.percentile15,
      mean_AccZ: featureZ.mean, std_AccZ: featureZ.std, median_AccZ: featureZ.median,
      abs_energy_AccZ: featureZ.absEnergy, skwness_AccZ: featureZ.skewness,
      emg_var_AccZ: featureZ.absEnergy / Double(bufferSize - 1),
      mean_crossings_AccZ: featureZ.meanCrossings, waveform_length_AccZ: featureZ.waveformLength,
      percentile_15_AccZ: featureZ.percentile15
    )
  }

  private static func calculateStandardDeviation(_ values: [Double]) -> Double? {
    guard values.count > 1 else { return 0.0 }

    let mean = calculateMean(values) ?? 0.0
    let squaredDifferences = values.map { pow($0 - mean, 2) }
    let variance = squaredDifferences.reduce(0, +) / Double(values.count - 1)

    return sqrt(variance)
  }

  private static func calculateSkewness(_ values: [Double]) -> Double? {
    guard values.count > 2 else { return 0.0 }

    let mean = calculateMean(values) ?? 0.0
    let std = calculateStandardDeviation(values) ?? 1.0

    guard std > 0 else { return 0.0 }

    let cubedDifferences = values.map { pow(($0 - mean) / std, 3) }
    let skewness = cubedDifferences.reduce(0, +) / Double(values.count)

    return skewness
  }

  private static func calculatePercentile(_ values: [Double], percentile: Double) -> Double? {
    guard !values.isEmpty else { return nil }
    guard percentile >= 0 && percentile <= 1 else { return nil }

    let sortedValues = values.sorted()
    let index = percentile * Double(sortedValues.count - 1)
    let lowerIndex = Int(floor(index))
    let upperIndex = Int(ceil(index))

    if lowerIndex == upperIndex {
      return sortedValues[lowerIndex]
    }

    let weight = index - Double(lowerIndex)
    return sortedValues[lowerIndex] * (1 - weight) + sortedValues[upperIndex] * weight
  }

  private static func calculateAxisFeatures(for values: [Double]) -> (
    mean: Double, std: Double, median: Double, absEnergy: Double, skewness: Double,
    meanCrossings: Double, waveformLength: Double, percentile15: Double
  ) {
    let mean = calculateMean(values) ?? 0.0
    let std = calculateStandardDeviation(values) ?? 0.0
    let median = calculateMedian(values) ?? 0.0
    let absEnergy = calculateAbsEnergy(values) ?? 0.0
    let skewness = calculateSkewness(values) ?? 0.0
    let meanCrossings = calculateZeroCrossings(values) ?? 0.0
    let waveformLength = calculateWaveformLength(values) ?? 0.0
    let percentile15 = calculatePercentile(values, percentile: 0.15) ?? 0.0

    return (mean, std, median, absEnergy, skewness, meanCrossings, waveformLength, percentile15)
  }

  private static func calculateMean(_ values: [Double]) -> Double? {
    let sum = values.reduce(0.0, +)
    return sum / Double(values.count)
  }

  private static func calculateMedian(_ values: [Double]) -> Double? {
    let sortedValues = values.sorted()
    let middleIndex = sortedValues.count / 2
    if sortedValues.count % 2 == 0 {
      return (sortedValues[middleIndex - 1] + sortedValues[middleIndex]) / 2.0
    } else {
      return sortedValues[middleIndex]
    }
  }

  private static func calculateAbsEnergy(_ values: [Double]) -> Double? {
    return values.map { $0 * $0 }.reduce(0, +)
  }

  private static func calculateZeroCrossings(_ values: [Double]) -> Double? {
    guard !values.isEmpty else { return 0 }

    var crossings = 0
    var previousValue = values.first!

    for value in values.dropFirst() {
      if previousValue * value < 0 {
        crossings += 1
      }
      previousValue = value
    }
    return Double(crossings)
  }

  private static func calculateWaveformLength(_ values: [Double]) -> Double? {
    guard values.count > 1 else { return 0.0 }

    var waveformLength = 0.0
    for i in 1..<values.count {
      waveformLength += abs(values[i] - values[i - 1])
    }

    return waveformLength
  }
}
