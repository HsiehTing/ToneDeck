//
//  MeshGradient.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/10/4.
//

import SwiftUI
import UIKit
import Combine

class UIKitMeshGradient: UIView {
    private var hostingController: UIHostingController<AnimatedColorMeshView>?
    private let colorSubject = CurrentValueSubject<Color, Never>(.blue)
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    private func setupView() {
        let swiftUIView = AnimatedColorMeshView(colorPublisher: colorSubject.eraseToAnyPublisher())
        hostingController = UIHostingController(rootView: swiftUIView)
        if let hostView = hostingController?.view {
            hostView.backgroundColor = .clear
            hostView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(hostView)
            NSLayoutConstraint.activate([
                hostView.topAnchor.constraint(equalTo: topAnchor),
                hostView.leadingAnchor.constraint(equalTo: leadingAnchor),
                hostView.trailingAnchor.constraint(equalTo: trailingAnchor),
                hostView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    func setTargetColor(_ color: UIColor) {
        let components = color.rgbaComponents
        setTargetColorRGBA(red: Double(components.red),
                           green: Double(components.green),
                           blue: Double(components.blue),
                           alpha: Double(components.alpha))
    }
    
    func setTargetColorRGBA(red: Double, green: Double, blue: Double, alpha: Double) {
        print("Setting target color: R: \(red), G: \(green), B: \(blue), A: \(alpha)")
        let newColor = Color(red: red, green: green, blue: blue, opacity: 1.0)
        colorSubject.send(newColor)
    }
    
    struct AnimatedColorMeshView: View {
        @State private var time: Float = 0.0
        @StateObject private var viewModel: ViewModel
        let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        init(colorPublisher: AnyPublisher<Color, Never>) {
            _viewModel = StateObject(wrappedValue: ViewModel(colorPublisher: colorPublisher))
        }
        private func positions(in size: CGSize) -> [SIMD2<Float>] {
            let aspectRatio = Float(size.width / size.height)
            let scaleFactor = min(Float(size.width), Float(size.height)) / 500.0
            return [
                [0.0, 0.0],
                [0.5, 0.0],
                [1.0, 0.0],
                [smoothSin(-0.8 * scaleFactor, 0.2 * scaleFactor, offset: 0.439, timeScale: 0.3),
                 smoothSin(0.2 * scaleFactor, 0.8 * scaleFactor, offset: 3.42, timeScale: 0.5)],
                [smoothSin(0.0 * scaleFactor, 1.0 * scaleFactor, offset: 0.239, timeScale: 0.1),
                 smoothSin(0.1 * scaleFactor, 0.9 * scaleFactor, offset: 5.21, timeScale: 0.2)],
                [smoothSin(0.8 * scaleFactor, 1.8 * scaleFactor, offset: 0.539, timeScale: 0.15),
                 smoothSin(0.3 * scaleFactor, 0.7 * scaleFactor, offset: 0.25, timeScale: 0.4)],
                [smoothSin(-1.0 * scaleFactor, 0.2 * scaleFactor, offset: 1.439, timeScale: 0.35),
                 smoothSin(0.9 * scaleFactor, 1.9 * scaleFactor, offset: 3.42, timeScale: 0.45)],
                [smoothSin(0.2 * scaleFactor, 0.8 * scaleFactor, offset: 0.339, timeScale: 0.5),
                 smoothSin(0.8 * scaleFactor, 1.4 * scaleFactor, offset: 1.22, timeScale: 0.3)],
                [smoothSin(0.8 * scaleFactor, 1.8 * scaleFactor, offset: 0.939, timeScale: 0.2),
                 smoothSin(0.9 * scaleFactor, 1.7 * scaleFactor, offset: 0.47, timeScale: 0.25)]
            ].map { [$0[0] * aspectRatio, $0[1]] }
        }
        
        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // 添加一個背景色，確保沒有透明部分

                   

                    Canvas { context, size in
                        let width = size.width
                        let height = size.height
                        
                        let scaledPositions = positions(in: size).map { point in
                            CGPoint(x: CGFloat(point.x) * width, y: CGFloat(point.y) * height)
                        }
                        
                        // 繪製背景
                        let backgroundRect = Path(CGRect(origin: .zero, size: size))
                        context.fill(backgroundRect, with: .color(viewModel.targetColor))
                        
                        for ivalue in 0..<2 {
                            for jvalue in 0..<2 {
                                let path = Path { pvalue in
                                    let point1 = scaledPositions[ivalue * 3 + jvalue]
                                    let point2 = scaledPositions[ivalue * 3 + jvalue + 1]
                                    let point3 = scaledPositions[(ivalue + 1) * 3 + jvalue + 1]
                                    let point4 = scaledPositions[(ivalue + 1) * 3 + jvalue]
                                    
                                    pvalue.move(to: point1)
                                    pvalue.addLine(to: point2)
                                    pvalue.addLine(to: point3)
                                    pvalue.addLine(to: point4)
                                    pvalue.closeSubpath()
                                }
                                
                                let gradient = Gradient(colors: [
                                    adjustColor(viewModel.targetColor, brightnessAdjustment: Double(ivalue + jvalue) / 3, saturationAdjustment: 0.2),
                                    adjustColor(viewModel.targetColor, brightnessAdjustment: Double(ivalue + jvalue + 1) / 3, saturationAdjustment: 0.1),
                                    adjustColor(viewModel.targetColor, brightnessAdjustment: Double(ivalue + jvalue + 2) / 3, saturationAdjustment: 0),
                                    adjustColor(viewModel.targetColor, brightnessAdjustment: Double(ivalue + jvalue + 1) / 3, saturationAdjustment: 0.1)
                                ])
                                
                                let startPoint = scaledPositions[ivalue * 3 + jvalue]
                                let endPoint = scaledPositions[(ivalue + 1) * 3 + jvalue + 1]
                                
                                context.fill(path, with: .linearGradient(
                                    gradient,
                                    startPoint: startPoint,
                                    endPoint: endPoint
                                ))
                            }
                        }
                    }
                    .blur(radius: min(30, min(geometry.size.width, geometry.size.height) / 10))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .onReceive(timer) { _ in
                    time += 0.05
                }
            }
            .ignoresSafeArea()
        }
        private func adjustColor(_ color: Color, brightnessAdjustment: Double, saturationAdjustment: Double) -> Color {
            let components = color.hsbaComponents
            let adjustedBrightness = min(max(components.brightness * brightnessAdjustment, 0.6), 1.3)
            let adjustedSaturation = min(max(components.saturation + saturationAdjustment, 0), 1)
            return Color(hue: components.hue, saturation: adjustedSaturation, brightness: adjustedBrightness, opacity: 1)
        }
        
        private func smoothSin(_ min: Float, _ max: Float, offset: Float, timeScale: Float) -> Float {
            let amplitude = (max - min) / 2
            let midPoint = (max + min) / 2
            return midPoint + amplitude * sin(timeScale * time + offset)
        }
    }
}

class ViewModel: ObservableObject {
    @Published var targetColor: Color = .blue

    init(colorPublisher: AnyPublisher<Color, Never>) {
        colorPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$targetColor)
    }
}
// Define a struct for RGBA components
struct RGBA {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}
struct RGBAComponents {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
}
extension Color {
    var rgbaComponents: RGBA {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGBA(red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
    }
}
extension UIColor {
    var rgbaComponents: RGBAComponents {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return RGBAComponents(red: red, green: green, blue: blue, alpha: alpha)
    }
}
struct HSBA {
    let hue: Double
    let saturation: Double
    let brightness: Double
    let alpha: Double
}

extension Color {
    var hsbaComponents: HSBA {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return HSBA(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness), alpha: Double(alpha))
    }
}
