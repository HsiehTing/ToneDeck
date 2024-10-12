//
//  ToneDeckApp.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import SwiftUI
import AuthenticationServices
import FirebaseCore
import Firebase

@main
struct ToneDeckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}

struct ContentView: View {
    @State private var isSignedIn = false

    var body: some View {
        ZStack {
            MeshGradient.AnimatedGrayscaleMeshView()
                .ignoresSafeArea()

            if isSignedIn {
                AfterSignInContentView()
            } else {
                VStack {
                    Spacer()
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                switch authResults.credential {
                                case let appleIDCredential as ASAuthorizationAppleIDCredential:
                                    let defaults = UserDefaults.standard
                                    defaults.set(appleIDCredential.user, forKey: "userDocumentID")
                                    if let fullName = appleIDCredential.fullName {
                                        let formattedName = "\(fullName.familyName ?? "") \(fullName.givenName ?? "")"
                                        defaults.set(formattedName, forKey: "userName")
                                    }
                                    defaults.set(appleIDCredential.email, forKey: "userEmail")
                                    checkAndAddCredentialsData(id: appleIDCredential.user, email: appleIDCredential.email ?? "")
                                    defaults.set(true, forKey: "isSignedIn")
                                    isSignedIn = true
                                case let passwordCredential as ASPasswordCredential:
                                    let defaults = UserDefaults.standard
                                    defaults.set(passwordCredential.user, forKey: "userDocumentID")
                                    defaults.set(passwordCredential.password, forKey: "password")
                                    defaults.set(true, forKey: "isSignedIn")
                                    defaults.set(true, forKey: "signinWithApple")
                                    isSignedIn = true
                                default:
                                    break
                                }
                                checkUserData()
                            case .failure(let error):
                                print("failure", error)
                            }
                        }
                    )
                    .frame(width: 170, height: 50)
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .padding()
                    Button(action: {
                        let defaults = UserDefaults.standard
                        defaults.set(false, forKey: "signinWithApple") // Set signinWithApple to false
                        isSignedIn = true // Allow the user to continue
                        checkUserData() // Call checkUserData()
                    }) {
                        Text("Continue without Sign In")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onAppear {
            checkIfSignedIn()
        }
    }

    private func checkIfSignedIn() {
        let defaults = UserDefaults.standard
        // Check if "isSignedIn" is false, meaning the user has logged in before
        if defaults.bool(forKey: "isSignedIn") == true {
            isSignedIn = true
        } else {
            defaults.set(false, forKey: "isSignedIn")
        }
    }
}
func checkAndAddCredentialsData(id: String, email: String) {
    let credentialsCollection = Firestore.firestore().collection("credentials")
    credentialsCollection.whereField("id", isEqualTo: id).getDocuments { (snapshot, error) in
        if let error = error {
            print("Error fetching documents: \(error)")
            return
        }
        if let snapshot = snapshot, !snapshot.isEmpty {
            print("ID already exists. No need to add.")
        } else {
            let document = credentialsCollection.document() // Firestore auto-generates a new document ID
            let data: [String: Any] = [
                "id": id,
                "email": email
            ]
            document.setData(data) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    print("Document successfully added.")
                }
            }
        }
    }
}

class MeshGradient {

    struct AnimatedGrayscaleMeshView: View {
        @State private var time: Float = 0.0

        let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

        private var positions: [SIMD2<Float>] {
            [
                [0.0, 0.0],
                [0.5, 0.0],
                [1.0, 0.0],
                [sinInRange(-0.5 ... -0.2, offset: 0.439, timeScale: 0.342), sinInRange(0.3...0.7, offset: 3.42, timeScale: 0.984)],
                [sinInRange(0.1...0.8, offset: 0.239, timeScale: 0.084), sinInRange(0.2...0.8, offset: 5.21, timeScale: 0.242)],
                [sinInRange(1.0...1.6, offset: 0.539, timeScale: 0.084), sinInRange(0.4...0.5, offset: 0.25, timeScale: 0.642)],
                [sinInRange(-0.8...0.0, offset: 1.439, timeScale: 0.442), sinInRange(1.4...1.9, offset: 3.42, timeScale: 0.984)],
                [sinInRange(0.3...0.6, offset: 0.339, timeScale: 0.784), sinInRange(1.0...1.2, offset: 1.22, timeScale: 0.772)],
                [sinInRange(1.0...1.5, offset: 0.939, timeScale: 0.056), sinInRange(1.3...1.7, offset: 0.47, timeScale: 0.342)],
            ]
        }

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Canvas { context, size in
                        let width = size.width
                        let height = size.height  // Adjust height to 2/3 of screen height

                        let scaledPositions = positions.map { point in
                            CGPoint(x: CGFloat(point.x) * width, y: CGFloat(point.y) * height)
                        }

                        // Draw gradient mesh
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
                                    Color(white: Double(ivalue + jvalue) / 3),
                                    Color(white: Double(ivalue + jvalue + 1) / 3),
                                    Color(white: Double(ivalue + jvalue + 2) / 3),
                                    Color(white: Double(ivalue + jvalue + 1) / 3),
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
                    .blur(radius: 30)
                    .layerEffect(ShaderLibrary.pixellate(.float(2)), maxSampleOffset: .zero)
                    .frame(height: geometry.size.height ) // Set the frame height
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // Center the view

                }
                .onReceive(timer) { _ in
                    time += 0.05

                }
                Color.black.opacity(0.3)
            }
            .ignoresSafeArea()
        }

        private func sinInRange(_ range: ClosedRange<Float>, offset: Float, timeScale: Float) -> Float {
            let amplitude = (range.upperBound - range.lowerBound) / 2
            let midPoint = (range.upperBound + range.lowerBound) / 2
            return midPoint + amplitude * sin(timeScale * time + offset)
        }
    }
}

