//
//  FilterManager.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/15.
//

import Foundation
import CoreImage
import UIKit

var dominantColor: UIColor?
func calculateBrightness(from histogramData: [String: [Float]]) -> Float {
    guard let grayHistogram = histogramData["gray"] else {
        return 0.0
    }
    let totalPixels = grayHistogram.reduce(0, +)
    if totalPixels == 0 {
        return 0.0
    }

    let darkWeight: Float = 0.5
    let midWeight: Float = 1.0
    let lightWeight: Float = 0.7

    let darkRange = 0...85
    let midRange = 86...170
    let lightRange = 171...255
    var darkSum: Float = 0.0
    var midSum: Float = 0.0
    var lightSum: Float = 0.0
    var darkPixels: Float = 0.0
    var midPixels: Float = 0.0
    var lightPixels: Float = 0.0

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

    let darkAverage = darkPixels > 0 ? (darkSum / darkPixels) * darkWeight : 0.0
    let midAverage = midPixels > 0 ? (midSum / midPixels) * midWeight : 0.0
    let lightAverage = lightPixels > 0 ? (lightSum / lightPixels) * lightWeight : 0.0

    let totalWeightedBrightness = (darkAverage + midAverage + lightAverage) / (darkWeight + midWeight + lightWeight)

    return totalWeightedBrightness / 255.0
}
func calculateContrastFromHistogram(histogramData: [String: [Float]]) -> Float {

    guard let grayHistogram = histogramData["gray"] else {
        return 0.0
    }

    let totalPixels = grayHistogram.reduce(0, +)
    if totalPixels == 0 {
        return 0.0
    }

    var brightnessSum: Float = 0.0
    for intensity in 0..<256 {
        brightnessSum += Float(grayHistogram[intensity]) * (Float(intensity) / 255.0)
    }
    let meanBrightness = brightnessSum / Float(totalPixels)

    var varianceSum: Float = 0.0
    for intensity in 0..<256 {
        let normalizedIntensity = Float(intensity) / 255.0
        let difference = normalizedIntensity - meanBrightness
        varianceSum += Float(grayHistogram[intensity]) * difference * difference
    }
    let variance = varianceSum / Float(totalPixels)

    let standardDeviation = sqrt(variance)
    return standardDeviation
}
func calculateSaturation(from histogramData: [String: [Float]]) -> Float {
    guard let redHistogram = histogramData["red"],
          let greenHistogram = histogramData["green"],
          let blueHistogram = histogramData["blue"],
          let grayHistogram = histogramData["gray"] else {
        return 0.0
    }

    let totalPixels = redHistogram.reduce(0, +)
    if totalPixels == 0 {
        return 0.0
    }

    var saturationSum: Float = 0.0

    for intensity in 0..<256 {
        let red = Float(redHistogram[intensity])
        let green = Float(greenHistogram[intensity])
        let blue = Float(blueHistogram[intensity])
        let gray = Float(grayHistogram[intensity])

        let colorDistance = sqrt(pow(red - gray, 2) + pow(green - gray, 2) + pow(blue - gray, 2))

        saturationSum += colorDistance
    }

    let averageSaturation = saturationSum / totalPixels
    return averageSaturation
}

func calculateColor(from histogramData: [String: [Float]]) -> [Float] {
    guard let redHistogram = histogramData["red"],
          let greenHistogram = histogramData["green"],
          let blueHistogram = histogramData["blue"],
          let grayHistogram = histogramData["gray"] else {
        return [0, 0, 0]
    }
    let redAverage = !redHistogram.isEmpty ? redHistogram.reduce(0, +) / Float(redHistogram.count) : 0
    let greenAverage = !greenHistogram.isEmpty ? greenHistogram.reduce(0, +) / Float(greenHistogram.count) : 0
    let blueAverage = !blueHistogram.isEmpty ? blueHistogram.reduce(0, +) / Float(blueHistogram.count) : 0

    let collorVectorArray = [redAverage, greenAverage, blueAverage]
    return collorVectorArray
}

func getDominantColor(from image: UIImage) -> Float {
    guard let ciImage = CIImage(image: image) else { return 0 }

    let scaleFilter = CIFilter(name: "CILanczosScaleTransform")!
    scaleFilter.setValue(ciImage, forKey: kCIInputImageKey)
    scaleFilter.setValue(0.1, forKey: kCIInputScaleKey)
    scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
    let scaledImage = scaleFilter.outputImage!

    let extent = scaledImage.extent
    let filter = CIFilter(name: "CIAreaAverage", parameters: [
        kCIInputImageKey: scaledImage,
        kCIInputExtentKey: CIVector(cgRect: extent)
    ])!

    guard let outputImage = filter.outputImage else { return 0 }

    let context = CIContext()
    var pixel = [UInt8](repeating: 0, count: 4)
    context.render(outputImage, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

    let red = CGFloat(pixel[0]) / 255.0
    let green = CGFloat(pixel[1]) / 255.0
    let blue = CGFloat(pixel[2]) / 255.0
    let alpha = CGFloat(pixel[3]) / 255.0
     dominantColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)

    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    guard let dominantColor = dominantColor else {return 0}
    dominantColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

    let hueInRadians = Float(hue * .pi * 2)
    print("Dominant color hue in radians: \(hueInRadians)")
    return hueInRadians
}

func hueValue(from color: UIColor) -> Float {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0
    color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

    return Float(hue * .pi * 2)
}
extension UIImage.Orientation {
    var exifOrientation: Int32 {
        switch self {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        }
    }
}
