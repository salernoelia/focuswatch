 //
//  emaModel.swift
//  FokusUhr Watch App
//
//  Created by Julian Amacker on 26.08.2024.
//

import Foundation

struct ModelParams: Codable {
    var samplingRateHz: Float = 100 // This should be dynamically assigned from the dataset's sampling rate
    var halflifeGSec: Float = 10.0 // halflife to estimate g with an exponential moving average
    var halflifeFastSec: Float = 0.1 // fast decay time constant for the exponential moving average (seconds)
    var halflifeTrendSec: Float = 0.3 // decay for variance trend smoothing (seconds)
    var halflifeSlowSec: Float = 5.0 // decay for the slow moving average of the variance
    var halflifeProbaFastSec: Float = 1.0 // decay for the fast moving average of the probability
    var halflifeProbaSlowSec: Float = 5.0 // decay for the slow moving average of the probability
    var halflifeProbaAvgSec: Float = 20.0 // decay for the averaging of the probability
    var budgetThinkSec: Float = 20.0 // time budget for thinking
    var threshProba: Float = 0.75 // threshold for probability to detect writing position
    var threshExponent: Float = -0.5 // threshold for exponent to detect writing position
    var coefXfMu: Float = 0.0 // mean for x component of fast variance
    var coefXfSigma: Float = 0.1 // standard deviation for x component of fast variance
    var coefZfMu: Float = 0.0 // mean for z component of fast variance
    var coefZfSigma: Float = 0.27 // standard deviation for z component of fast variance
    var coefVfminMu: Float = 0.04 // mean for min value of fast variance
    var coefVfminSigma: Float = 1.4 // standard deviation for min value of fast variance
    var coefVfmaxMu: Float = 0.1 // mean for max value of fast variance
    var coefVfmaxSigma: Float = 1.4 // standard deviation for max value of fast variance
    var coefVsMu: Float = 0.1242 // mean for slow variance
    var coefVsSigma: Float = 1.22 // standard deviation for slow variance
    var slopeExponent: Float = 1.0
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
}


func writingModel(XYZ: [[Float]], params: ModelParams, initState: ModelState?) -> ModelState {
    let LN2 = log(2.0 as Float)
    //let ZERO: Float = 0.0
    let NMAX_G_AV = 100  // max number of samples for g normalization

    // Prepare parameters used in the model
    let samplingFrequency = params.samplingRateHz
    let alphaG = 1 - exp(-LN2 / (params.halflifeGSec * samplingFrequency))
    let alphaFast = 1 - exp(-LN2 / (params.halflifeFastSec * samplingFrequency))
    let alphaTrend = 1 - exp(-LN2 / (params.halflifeTrendSec * samplingFrequency))
    let alphaSlow = 1 - exp(-LN2 / (params.halflifeSlowSec * samplingFrequency))
    let alphaProbaSlow = 1 - exp(-LN2 / (params.halflifeProbaSlowSec * samplingFrequency))
    let alphaProbaFast = 1 - exp(-LN2 / (params.halflifeProbaFastSec * samplingFrequency))
    let alphaProbaAvg = 1 - exp(-LN2 / (params.halflifeProbaAvgSec * samplingFrequency))
    let vf2maxMu = params.coefVfmaxMu * params.coefVfmaxMu
    let vf2minMu = params.coefVfminMu * params.coefVfminMu
    let vs2Mu = params.coefVsMu * params.coefVsMu
    let thinkCountBudget = Int(params.budgetThinkSec * samplingFrequency)
    let N = XYZ.count // number of samples

    // Provide initial state if not given
    var state: ModelState

    // Check if initState is provided
    if let initialState = initState {
        state = initialState
    } else {
        // No initial state provided, compute the initial state values
        // Calculate an initial estimate for g
        var g: Float = 0.0
        for i in 0..<min(N, NMAX_G_AV) {
            let gi = sqrt(XYZ[i][0] * XYZ[i][0] + XYZ[i][1] * XYZ[i][1] + XYZ[i][2] * XYZ[i][2])
            g += gi
        }
        g /= Float(min(N, NMAX_G_AV))

        // Provide initial state using calculated values
        state = ModelState(
            index: 0,
            g: g,
            xf: XYZ[0][0] / g, yf: XYZ[0][1] / g, zf: XYZ[0][2] / g,
            vf2: 1.0, vf2t: 0.0,
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
            thinkCount: 0,
            status: 0
        )
    }

    // Loop over all samples
    for i in 0..<N {
        // Update g estimation
        let x = XYZ[i][0]
        let y = XYZ[i][1]
        let z = XYZ[i][2]
        let gi = sqrt(x * x + y * y + z * z)
        state.g += alphaG * (gi - state.g)

        // Comparison of fast variance with trend before update
        let preCompVf = state.vf2 > state.vf2t

        // Fast filter to detect hand movements
        let dxf = x / state.g - state.xf
        let dyf = y / state.g - state.yf
        let dzf = z / state.g - state.zf
        let d2f = dxf * dxf + dyf * dyf + dzf * dzf

        state.xf += alphaFast * dxf
        state.yf += alphaFast * dyf
        state.zf += alphaFast * dzf

        state.vf2 += alphaFast * (d2f - state.vf2)
        state.vf2t += alphaTrend * (state.vf2 - state.vf2t)

        // Slow filter to detect writing position
        let dxs = state.xf - state.xs
        let dys = state.yf - state.ys
        let dzs = state.zf - state.zs
        let d2s = dxs * dxs + dys * dys + dzs * dzs

        state.xs += alphaSlow * dxs
        state.ys += alphaSlow * dys
        state.zs += alphaSlow * dzs
        state.vs2 += alphaSlow * (d2s - state.vs2)

        // Comparison of fast variance with trend after update
        let postCompVf = state.vf2 > state.vf2t

        // Check whether there is crossing of variance with variance trend
        var reset = false
        if preCompVf && !postCompVf {
            state.xfcross = state.xf
            state.yfcross = state.yf
            state.zfcross = state.zf
            state.vf2maxcross = state.vf2max
            state.vf2mincross = state.vf2min
            state.vs2cross = state.vs2

            // Calculate exponent
            var exponent: Float = 0.0
            if params.coefXfSigma > 0 {
                let value = (state.xfcross - params.coefXfMu) / params.coefXfSigma
                exponent += Float(1 - value * value / 2)
            }
            if params.coefZfSigma > 0 {
                let value = (state.zfcross - params.coefZfMu) / params.coefZfSigma
                exponent += Float(1 - value * value / 2)
            }
            if params.coefVfminSigma > 0 {
                let value = log(state.vf2mincross / vf2minMu) / (params.coefVfminSigma * 2)
                exponent += Float(1 - value * value / 2)
            }
            if params.coefVfmaxSigma > 0 {
                let value = log(state.vf2maxcross / vf2maxMu) / (params.coefVfmaxSigma * 2)
                exponent += Float(1 - value * value / 2)
            }
            if params.coefVsSigma > 0 {
                let value = log(state.vs2cross / vs2Mu) / (params.coefVsSigma * 2)
                exponent += Float(1 - value * value / 2)
            }

            state.exponent = exponent
            state.proba = exp(params.slopeExponent * (exponent - params.threshExponent))
            state.proba /= 1 + state.proba
            state.periodSec = Float(state.periodCount) / samplingFrequency

            state.periodCount = 1
            reset = true
        }

        // Update variance calculation values, capture max and min values
        let vf2val = state.vf2
        if reset || (vf2val > state.vf2max) {
            state.vf2max = vf2val
        }
        if reset || (vf2val > state.vf2max) || (vf2val < state.vf2min) {
            state.vf2min = vf2val
        }

        state.periodCount += 1
        state.index += 1

        // Update proba filters and status
        state.probaSlow += alphaProbaSlow * (state.proba - state.probaSlow)
        state.probaFast += alphaProbaFast * (state.proba - state.probaFast)
        state.probaAvg += alphaProbaAvg * (state.proba - state.probaAvg)

        let slowFlag = state.probaSlow >= params.threshProba
        let fastFlag = state.probaFast >= params.threshProba
        let thinkFlag = state.thinkCount > 0

        // Writing status
        if slowFlag && fastFlag {
            state.status = 0
            state.thinkCount = Int(state.probaAvg * Float(thinkCountBudget))
        } else if thinkFlag || (slowFlag && !fastFlag) {
            state.status = 1
            state.thinkCount -= 1
        } else if !thinkFlag && !slowFlag && !fastFlag {
            state.status = 2
            state.thinkCount = 0
        } else if fastFlag && !slowFlag {
            state.status = 3
            state.thinkCount = 0
        } else {
            state.status = -1
        }
    }

    return state
}
