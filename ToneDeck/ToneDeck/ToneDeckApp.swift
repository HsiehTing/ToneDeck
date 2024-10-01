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
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
      WindowGroup {
        NavigationView {
            //AfterSignInContentView()
            ContentView()

        }
      }
    }
}

struct ContentView: View {
    @State private var isSignedIn = false
    var body: some View {
        if isSignedIn {
            // Navigate to AfterSignInContentView after login
            AfterSignInContentView()
        } else {
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            print(appleIDCredential.fullName, appleIDCredential.email, appleIDCredential.user)
                            let defaults = UserDefaults.standard
                            defaults.set(appleIDCredential.user, forKey: "userDocumentID")
                            if let fullName = appleIDCredential.fullName {
                                    let formattedName = "\(fullName.familyName ?? "") \(fullName.givenName ?? "")"
                                    defaults.set(formattedName, forKey: "userName")
                                }
                            defaults.set(appleIDCredential.email, forKey: "userEmail")
                            checkAndAddCredentialsData(id: appleIDCredential.user, email: appleIDCredential.email ?? "")
                            isSignedIn = true
                        case let passwordCredential as ASPasswordCredential:
                            let username = passwordCredential.user
                            let password = passwordCredential.password
                            let defaults = UserDefaults.standard
                            defaults.set(passwordCredential.user, forKey: "userDocumentID")
                            defaults.set(passwordCredential.password, forKey: "password")
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
}
