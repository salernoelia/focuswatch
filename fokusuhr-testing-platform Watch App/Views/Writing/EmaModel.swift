import Foundation

struct ModelParams: Codable {

  var samplingRateHz: Float = 25  // This should be dynamically assigned from the dataset's sampling rate
  var halflifeGSec: Float = 10.0  // halflife to estimate g with an exponential moving average
  var halflifeFastSec: Float = 0.1  // fast decay time constant for the exponential moving average (seconds)
  var halflifeTrendSec: Float = 0.3  // decay for variance trend smoothing (seconds)
  var halflifeSlowSec: Float = 5.0  // decay for the slow moving average of the variance
  var halflifeProbaFastSec: Float = 1.0  // decay for the fast moving average of the probability
  var halflifeProbaSlowSec: Float = 5.0  // decay for the slow moving average of the probability
  var halflifeProbaAvgSec: Float = 20.0  // decay for the averaging of the probability
  var budgetThinkSec: Float = 20.0  // time budget for thinking
  var threshProba: Float = 0.75  // threshold for probability to detect writing position
  var threshExponent: Float = -0.5  // threshold for exponent to detect writing position
  var coefXfMu: Float = 0.0  // mean for x component of fast variance
  var coefXfSigma: Float = 0.1  // standard deviation for x component of fast variance
  var coefZfMu: Float = 0.0  // mean for z component of fast variance
  var coefZfSigma: Float = 0.27  // standard deviation for z component of fast variance
  var coefVfminMu: Float = 0.04  // mean for min value of fast variance
  var coefVfminSigma: Float = 1.4  // standard deviation for min value of fast variance
  var coefVfmaxMu: Float = 0.1  // mean for max value of fast variance
  var coefVfmaxSigma: Float = 1.4  // standard deviation for max value of fast variance
  var coefVsMu: Float = 0.1242  // mean for slow variance
  var coefVsSigma: Float = 1.22  // standard deviation for slow variance
  var slopeExponent: Float = 1.0  // slope exponent for motion level adjustment
  var motionThreshold: Float = 0.002  // threshold for motion detection
  var stillnessThreshold: Float = 0.0005  // threshold for stillness detection
  var motionRecoveryFactor: Float = 0.3  // recovery factor for motion budget
}

struct ModelState {
  var index: Int
  var g: Float
  var xf: Float
  var yf: Float
  var zf: Float
  var vf2: Float
  var vf2t: Float
  var vf2max: Float
  var vf2min: Float
  var xs: Float
  var ys: Float
  var zs: Float
  var vs2: Float
  var xfcross: Float
  var yfcross: Float
  var zfcross: Float
  var vf2maxcross: Float
  var vf2mincross: Float
  var vs2cross: Float
  var periodSec: Float
  var periodCount: Int
  var exponent: Float
  var proba: Float
  var probaSlow: Float
  var probaFast: Float
  var probaAvg: Float
  var thinkCount: Int
  var status: Int
  var motionLevel: Float
  var motionAvg: Float
  var stillnessCount: Int
  var motionCount: Int
}

func writingModel(XYZ: [[Float]], params: ModelParams, initState: ModelState?) -> ModelState {
  let LN2 = log(2.0 as Float)
  let NMAX_G_AV = 100

  let samplingFrequency = params.samplingRateHz
  let alphaG = 1 - exp(-LN2 / (params.halflifeGSec * samplingFrequency))
  let alphaFast = 1 - exp(-LN2 / (params.halflifeFastSec * samplingFrequency))
  let alphaMotion: Float = 1 - exp(-LN2 / (0.5 * samplingFrequency))
  let thinkCountBudget = Int(params.budgetThinkSec * samplingFrequency)
  let stillnessRequired = Int(2.0 * samplingFrequency)
  let motionRequired = Int(0.3 * samplingFrequency)
  let N = XYZ.count

  guard N > 0 else {
    if let state = initState { return state }
    return createDefaultState(params: params)
  }

  var state: ModelState
  if let initialState = initState {
    state = initialState
  } else {
    var g: Float = 0.0
    for i in 0..<min(N, NMAX_G_AV) {
      let gi = sqrt(XYZ[i][0] * XYZ[i][0] + XYZ[i][1] * XYZ[i][1] + XYZ[i][2] * XYZ[i][2])
      g += gi
    }
    g /= Float(min(N, NMAX_G_AV))
    if g < 0.1 { g = 1.0 }

    state = ModelState(
      index: 0,
      g: g,
      xf: XYZ[0][0] / g, yf: XYZ[0][1] / g, zf: XYZ[0][2] / g,
      vf2: 0.0, vf2t: 0.0,
      vf2max: 0.0, vf2min: 2.0,
      xs: XYZ[0][0] / g, ys: XYZ[0][1] / g, zs: XYZ[0][2] / g,
      vs2: 0.0,
      xfcross: XYZ[0][0] / g, yfcross: XYZ[0][1] / g, zfcross: XYZ[0][2] / g,
      vf2maxcross: 0.1, vf2mincross: 0.05,
      vs2cross: 0.1,
      periodSec: 0.0,
      periodCount: 0,
      exponent: 0.0,
      proba: params.threshProba,
      probaSlow: params.threshProba,
      probaFast: params.threshProba,
      probaAvg: params.threshProba,
      thinkCount: thinkCountBudget,
      status: 0,
      motionLevel: 0.0,
      motionAvg: 0.0,
      stillnessCount: 0,
      motionCount: 0
    )
  }

  for i in 0..<N {
    let x = XYZ[i][0]
    let y = XYZ[i][1]
    let z = XYZ[i][2]
    let gi = sqrt(x * x + y * y + z * z)
    state.g += alphaG * (gi - state.g)

    let gSafe = max(state.g, 0.1)
    let dxf = x / gSafe - state.xf
    let dyf = y / gSafe - state.yf
    let dzf = z / gSafe - state.zf
    let d2f = dxf * dxf + dyf * dyf + dzf * dzf

    state.xf += alphaFast * dxf
    state.yf += alphaFast * dyf
    state.zf += alphaFast * dzf
    state.vf2 += alphaFast * (d2f - state.vf2)

    state.motionLevel = d2f
    state.motionAvg += alphaMotion * (d2f - state.motionAvg)

    let isMoving = state.motionAvg > params.motionThreshold
    let isStill = state.motionAvg < params.stillnessThreshold

    if isMoving {
      state.motionCount += 1
      state.stillnessCount = 0
    } else if isStill {
      state.stillnessCount += 1
      state.motionCount = max(0, state.motionCount - 1)
    }

    let confirmedMotion = state.motionCount >= motionRequired
    let confirmedStillness = state.stillnessCount >= stillnessRequired

    if confirmedMotion {
      state.status = 0
      let recoveryAmount = Int(Float(thinkCountBudget) * params.motionRecoveryFactor)
      state.thinkCount = min(thinkCountBudget, state.thinkCount + recoveryAmount)
      state.proba = 0.9
    } else if state.thinkCount > 0 && !confirmedStillness {
      state.status = 1
      state.thinkCount -= 1
      state.proba = Float(state.thinkCount) / Float(thinkCountBudget)
    } else if confirmedStillness {
      state.status = 2
      state.thinkCount = max(0, state.thinkCount - 2)
      state.proba = 0.1
    } else {
      state.status = 1
      state.proba = 0.5
    }

    state.index += 1
  }

  return state
}

private func createDefaultState(params: ModelParams) -> ModelState {
  let thinkCountBudget = Int(params.budgetThinkSec * params.samplingRateHz)
  return ModelState(
    index: 0,
    g: 1.0,
    xf: 0, yf: 0, zf: 0,
    vf2: 0.0, vf2t: 0.0,
    vf2max: 0.0, vf2min: 2.0,
    xs: 0, ys: 0, zs: 0,
    vs2: 0.0,
    xfcross: 0, yfcross: 0, zfcross: 0,
    vf2maxcross: 0.1, vf2mincross: 0.05,
    vs2cross: 0.1,
    periodSec: 0.0,
    periodCount: 0,
    exponent: 0.0,
    proba: params.threshProba,
    probaSlow: params.threshProba,
    probaFast: params.threshProba,
    probaAvg: params.threshProba,
    thinkCount: thinkCountBudget,
    status: 0,
    motionLevel: 0.0,
    motionAvg: 0.0,
    stillnessCount: 0,
    motionCount: 0
  )
}
