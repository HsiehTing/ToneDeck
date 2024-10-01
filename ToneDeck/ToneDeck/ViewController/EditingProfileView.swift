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

struct EditingProfileView: View {
    @State private var userName: String = ""
    @State private var avatarImage: UIImage?
    @State private var avatarItem: PhotosPickerItem?
    @State private var isStatusActive: Bool = false
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
                    Image(systemName: firestoreService.user?.avatar ?? "")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
            }
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
            Toggle("Active Status", isOn: $isStatusActive)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            Spacer()
        }
        .padding()
        .onAppear {
            guard let fromUserID = fromUserID else {return}
            firestoreService.fetchUserData(userID: fromUserID)
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

#Preview {
    EditingProfileView()
}
