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

        // 分別計算紅、綠、藍通道的直方圖
        let redHistogram = calculateColorChannelHistogram(for: ciImage, extent: extent, scale: scale, colorIndex: 0)
        let greenHistogram = calculateColorChannelHistogram(for: ciImage, extent: extent, scale: scale, colorIndex: 1)
        let blueHistogram = calculateColorChannelHistogram(for: ciImage, extent: extent, scale: scale, colorIndex: 2)

        // 計算灰階直方圖
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

    // 計算指定顏色通道的直方圖數據
    private func calculateColorChannelHistogram(for ciImage: CIImage, extent: CGRect, scale: Float, colorIndex: Int) -> [Float] {
        let histogramFilter = CIFilter.areaHistogram()
        histogramFilter.inputImage = ciImage
        histogramFilter.count = 256
        histogramFilter.extent = extent
        histogramFilter.scale = scale

        // 渲染每個顏色通道的直方圖數據
        let context = CIContext()
        var bitmap = [Float](repeating: 0, count: 256)
        context.render(histogramFilter.outputImage!, toBitmap: &bitmap, rowBytes: 256 * MemoryLayout<Float>.size, bounds: CGRect(x: 0, y: colorIndex, width: 256, height: 1)
                       , format: .Rf, colorSpace: nil)

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


