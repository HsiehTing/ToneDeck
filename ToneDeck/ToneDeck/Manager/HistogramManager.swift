//
//  HistogramManager.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/14.
//

import SwiftUI
import CoreImage
import Accelerate
import UIKit
import CoreImage.CIFilterBuiltins

class ImageHistogramCalculator: ObservableObject {

    @Published var filterHistogramData: [String: [Float]] = [:]

    func calculateHistogram(for image: UIImage) -> [String: [Float]] {
        guard let ciImage = CIImage(image: image) else {
            print("+++++ Failed to convert UIImage to CIImage.")
            return ["none": [0]]
        }

        let totalPixels = getTotalPixels(from: image)
        let scale = Float(totalPixels) / 256.0

        let extent = ciImage.extent

        let redHistogram = calculateRGBHistogram(for: ciImage, extent: extent, scale: scale, channel: "red")
        let greenHistogram = calculateRGBHistogram(for: ciImage, extent: extent, scale: scale, channel: "green")
        let blueHistogram = calculateRGBHistogram(for: ciImage, extent: extent, scale: scale, channel: "blue")
        let grayHistogram = calculateGrayScaleHistogram(for: ciImage, extent: extent, scale: scale)

        DispatchQueue.main.async {

            let histogramData = [
                "red": redHistogram,
                "green": greenHistogram,
                "blue": blueHistogram,
                "gray": grayHistogram
            ]
            self.filterHistogramData = histogramData
        }
        return ["red": redHistogram, "green": greenHistogram, "blue": blueHistogram, "gray": grayHistogram]
    }

    private func calculateRGBHistogram(for ciImage: CIImage, extent: CGRect, scale: Float, channel: String) -> [Float] {

        let channelFilter = CIFilter.colorMatrix()
        channelFilter.inputImage = ciImage

        switch channel {
        case "red":
            channelFilter.rVector = CIVector(x: 1, y: 0, z: 0, w: 0)
            channelFilter.gVector = CIVector(x: 0, y: 0, z: 0, w: 0)
            channelFilter.bVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        case "green":
            channelFilter.rVector = CIVector(x: 0, y: 0, z: 0, w: 0)
            channelFilter.gVector = CIVector(x: 0, y: 1, z: 0, w: 0)
            channelFilter.bVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        case "blue":
            channelFilter.rVector = CIVector(x: 0, y: 0, z: 0, w: 0)
            channelFilter.gVector = CIVector(x: 0, y: 0, z: 0, w: 0)
            channelFilter.bVector = CIVector(x: 0, y: 0, z: 1, w: 0)
        default:
            return [Float](repeating: 0, count: 256)
        }

        channelFilter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)

        guard let outputImage = channelFilter.outputImage else {
            print("ColorMatrix filter output is nil")
            return [Float](repeating: 0, count: 256)
        }

        let histogramFilter = CIFilter.areaHistogram()
        histogramFilter.inputImage = outputImage
        histogramFilter.count = 256
        histogramFilter.extent = extent
        histogramFilter.scale = scale

        let context = CIContext()
        var bitmap = [Float](repeating: 0, count: 256)
        context.render(histogramFilter.outputImage!, toBitmap: &bitmap, rowBytes: 256 * MemoryLayout<Float>.size, bounds: CGRect(x: 0, y: 0, width: 256, height: 1), format: .rgbXf, colorSpace: nil)

        return bitmap
    }

    private func calculateGrayScaleHistogram(for ciImage: CIImage, extent: CGRect, scale: Float) -> [Float] {

        let grayFilter = CIFilter.colorControls()
        grayFilter.inputImage = ciImage
        grayFilter.saturation = 0.0

        let histogramFilter = CIFilter.areaHistogram()
        histogramFilter.inputImage = grayFilter.outputImage
        histogramFilter.count = 256
        histogramFilter.extent = extent
        histogramFilter.scale = scale

        let context = CIContext()
        var bitmap = [Float](repeating: 0, count: 256)
        context.render(histogramFilter.outputImage!, toBitmap: &bitmap, rowBytes: 256 * MemoryLayout<Float>.size, bounds: CGRect(x: 0, y: 0, width: 256, height: 1), format: .Rf, colorSpace: nil)

        return bitmap
    }

    private func getTotalPixels(from image: UIImage) -> Int {
        let width = image.size.width
        let height = image.size.height
        return Int(width * height)
    }
}
