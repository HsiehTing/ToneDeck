//
//  EditingProfileView.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/10/1.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import Firebase
import Kingfisher

struct EditingProfileView: View {
    @State private var userName: String = ""
    @State private var avatarImage: UIImage?
    @State private var avatarItem: PhotosPickerItem?
    @State private var isStatusActive: Bool = UserDefaults.standard.bool(forKey: "privacyStatus")
    @Binding var userData: User?
    let firestoreService = FirestoreService()
    let fromUserID = UserDefaults.standard.string(forKey: "userDocumentID")
    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                if let avatarImage = avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))

                } else {
                    if let userData = userData {
                        KFImage(URL(string: userData.avatar) )
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            .shadow(radius: 10)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .onChange(of: avatarItem) { _ in
                Task {
                    if let data = try? await avatarItem?.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            avatarImage = uiImage
                            await updateAvatar()
                        }
                    }
                }
            }
            // Username
            TextField("Username", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .onChange(of: userName) { oldValue, newValue in
                    updateUserName()
                }
            // Status Toggle
            Toggle("Private account", isOn: $isStatusActive)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .onChange(of: isStatusActive) { oldValue, newValue in
                    guard let fromUserID = fromUserID else {return}
                    UserDefaults.standard.set(isStatusActive, forKey: "privacyStatus")
                    firestoreService.updateUserStatus(status: isStatusActive)
                }
            Button {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first {
                    let defaults = UserDefaults.standard
                    defaults.set(false, forKey: "isSignedIn")
                    defaults.removeObject(forKey: "userDocumentID")
                    defaults.removeObject( forKey: "blockPostsArray")
                                    window.rootViewController = UIHostingController(rootView: ContentView())
                                    window.makeKeyAndVisible()
                                }
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.forward")
            }
            .buttonStyle(PlainButtonStyle())
            Button {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first {
                    let defaults = UserDefaults.standard
                    defaults.set(false, forKey: "isSignedIn")
                    defaults.removeObject(forKey: "userDocumentID")
                    defaults.removeObject( forKey: "blockPostsArray")
                                    window.rootViewController = UIHostingController(rootView: ContentView())
                                    window.makeKeyAndVisible()
                                }
                firestoreService.updateDeleteStatus(status: true)

            } label: {
                Text("Delete Account")
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
        .padding()
        .onAppear {
//            guard let fromUserID = fromUserID else {return}
//            firestoreService.fetchUserData(userID: fromUserID)

        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
    }

    private func updateAvatar() async {
        guard let fromUserID = fromUserID, let image = avatarImage, let imageData = image.jpegData(compressionQuality: 0.8) else { return }

                let storageRef = Storage.storage().reference().child("avatars/\(fromUserID).jpg")

                do {
                    _ = try await storageRef.putDataAsync(imageData)
                    let downloadURL = try await storageRef.downloadURL()
                    firestoreService.updateUserAvatar(userID: fromUserID, newAvatarURL: downloadURL.absoluteString)
                } catch {
                    print("Error uploading image: \(error.localizedDescription)")
                }
    }
    private func updateUserName() {
            guard let fromUserID = fromUserID else { return }
            firestoreService.updateUserName(userID: fromUserID, newName: userName)
        }
}


