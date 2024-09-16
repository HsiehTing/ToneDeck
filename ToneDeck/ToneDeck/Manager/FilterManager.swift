//
//  FilterManager.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/15.
//

import Foundation

func calculateBrightness(from histogramData: [String: [Float]]) -> Float {
    guard let grayHistogram = histogramData["gray"] else {
        return 0.0
    }

    let totalPixels = grayHistogram.reduce(0, +)
    if totalPixels == 0 {
        return 0.0
    }

    // 調整權重：讓各個區間的權重更均衡
    let darkWeight: Float = 1.0
    let midWeight: Float = 1.0
    let lightWeight: Float = 1.0

    // 定義亮度區間
    let darkRange = 0...85
    let midRange = 86...170
    let lightRange = 171...255

    var darkSum: Float = 0.0
    var midSum: Float = 0.0
    var lightSum: Float = 0.0

    var darkPixels: Float = 0.0
    var midPixels: Float = 0.0
    var lightPixels: Float = 0.0

    // 計算各個區間的亮度和像素數
    for intensity in darkRange {
        darkSum += Float(grayHistogram[intensity]) * Float(intensity)
        darkPixels += Float(grayHistogram[intensity])
    }

    for intensity in midRange {
        midSum += Float(grayHistogram[intensity]) * Float(intensity)
        midPixels += Float(grayHistogram[intensity])
    }

    for intensity in lightRange {
        lightSum += Float(grayHistogram[intensity]) * Float(intensity)
        lightPixels += Float(grayHistogram[intensity])
    }

    // 計算各區間的平均亮度，並進行加權處理
    let darkAverage = darkPixels > 0 ? (darkSum / darkPixels) * darkWeight : 0.0
    let midAverage = midPixels > 0 ? (midSum / midPixels) * midWeight : 0.0
    let lightAverage = lightPixels > 0 ? (lightSum / lightPixels) * lightWeight : 0.0

    // 加權總和並計算亮度
    let totalWeightedBrightness = (darkAverage + midAverage + lightAverage) / (darkWeight + midWeight + lightWeight)

    // 標準化範圍 0 到 1
    return totalWeightedBrightness / 255.0
}

func calculateContrastFromHistogram(histogramData: [String: [Float]]) -> Float {
    // 確保有灰度直方圖數據
    guard let grayHistogram = histogramData["gray"] else {
        return 0.0
    }

    // 計算圖像的總像素數
    let totalPixels = grayHistogram.reduce(0, +)
    if totalPixels == 0 {
        return 0.0
    }

    // 計算亮度的平均值
    var brightnessSum: Float = 0.0
    for intensity in 0..<256 {
        brightnessSum += Float(grayHistogram[intensity]) * Float(intensity)
    }
    let meanBrightness = brightnessSum / Float(totalPixels)

    // 計算亮度的方差
    var varianceSum: Float = 0.0
    for intensity in 0..<256 {
        let difference = Float(intensity) - meanBrightness
        varianceSum += Float(grayHistogram[intensity]) * difference * difference
    }
    let variance = varianceSum / Float(totalPixels)

    // 標準差（即對比度的測量值）
    let standardDeviation = sqrt(variance)

    // 根據應用場景，調整對比度範圍。例如映射到 0 到 4 的範圍。
    // 若你想將標準差映射到 0.25 至 4 的範圍，可以這樣做：
    let contrast = max(0.25, min(4.0, standardDeviation / 64.0)) // 調整標準化範圍

    return contrast
}


func calculateSaturation(from histogramData: [String: [Float]]) -> Float {
    guard let redHistogram = histogramData["red"],
          let greenHistogram = histogramData["green"],
          let blueHistogram = histogramData["blue"],
          let grayHistogram = histogramData["gray"] else {
        return 0.0
    }

    let totalPixels = redHistogram.reduce(0, +) // 假設所有通道的像素總數相同
    if totalPixels == 0 {
        return 0.0
    }

    var saturationSum: Float = 0.0

    // 計算每個像素的飽和度，通過 RGB 和灰度值之間的距離來計算
    for intensity in 0..<256 {
        let red = Float(redHistogram[intensity])
        let green = Float(greenHistogram[intensity])
        let blue = Float(blueHistogram[intensity])
        let gray = Float(grayHistogram[intensity])

        // 計算彩色距離
        let colorDistance = sqrt(pow(red - gray, 2) + pow(green - gray, 2) + pow(blue - gray, 2))
        
        // 累計每個像素的飽和度值
        saturationSum += colorDistance
    }

    // 平均飽和度
    let averageSaturation = saturationSum / totalPixels
    return averageSaturation  // 標準化為 0 到 1 之間
}


