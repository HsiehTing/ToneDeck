//
//  HistogramManager.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/14.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

class ImageHistogramCalculator: ObservableObject {

    @Published var filterHistogramData: [String: [Float]] = [:]

    // 計算目標圖像的四種直方圖數據：紅、綠、藍、灰
    func calculateHistogram(for image: UIImage) -> [String: [Float]] {
        guard let ciImage = CIImage(image: image) else {
            print("Failed to convert UIImage to CIImage.")
            return ["none": [0]]
        }

        // 計算圖像的像素數以動態調整縮放比例
        let totalPixels = getTotalPixels(from: image)
        let scale = Float(totalPixels) / 256.0

        let extent = ciImage.extent

        // 計算 RGB 和灰階直方圖
        let redHistogram = calculateRGBHistogram(for: ciImage, extent: extent, scale: scale, channel: "red")
        let greenHistogram = calculateRGBHistogram(for: ciImage, extent: extent, scale: scale, channel: "green")
        let blueHistogram = calculateRGBHistogram(for: ciImage, extent: extent, scale: scale, channel: "blue")
        let grayHistogram = calculateGrayScaleHistogram(for: ciImage, extent: extent, scale: scale)

        DispatchQueue.main.async {
            // 將結果存儲到字典中
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

    // 計算RGB直方圖數據
    private func calculateRGBHistogram(for ciImage: CIImage, extent: CGRect, scale: Float, channel: String) -> [Float] {
        // 根據選擇的顏色通道應用不同的篩選器
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

        // 計算所選顏色通道的直方圖
        let histogramFilter = CIFilter.areaHistogram()
        histogramFilter.inputImage = channelFilter.outputImage
        histogramFilter.count = 256
        histogramFilter.extent = extent
        histogramFilter.scale = scale

        let context = CIContext()
        var bitmap = [Float](repeating: 0, count: 256)
        context.render(histogramFilter.outputImage!, toBitmap: &bitmap, rowBytes: 256 * MemoryLayout<Float>.size, bounds: CGRect(x: 0, y: 0, width: 256, height: 1), format: .rgbXf, colorSpace: nil)

        return bitmap
    }

    // 計算灰階直方圖數據
    private func calculateGrayScaleHistogram(for ciImage: CIImage, extent: CGRect, scale: Float) -> [Float] {
        // 將圖像轉換為灰階
        let grayFilter = CIFilter.colorControls()
        grayFilter.inputImage = ciImage
        grayFilter.saturation = 0.0

        // 計算灰階的直方圖
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

    // 計算圖像總像素數
    private func getTotalPixels(from image: UIImage) -> Int {
        let width = image.size.width
        let height = image.size.height
        return Int(width * height)
    }
}
