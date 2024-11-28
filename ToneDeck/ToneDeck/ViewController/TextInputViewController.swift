//
//  TextInputViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/16.
//

import SwiftUI
import Combine
import FirebaseFirestore
import Kingfisher

class TextInputViewModel: ObservableObject {
    @Published var postText: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Environment(\.presentationMode) var presentationMode
    private var cancellables = Set<AnyCancellable>()
    let photo: Photo
    private let onDismiss: (() -> Void)?

    init(photo: Photo, onDismiss: ( () -> Void)?) {
        self.photo = photo
        self.onDismiss = onDismiss
    }
    func clearError() {
            error = nil
        }
    func publishPost () {
        isLoading = true
        error = nil
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid instance"])))
                return
            }
            let db = Firestore.firestore()
            let posts = Firestore.firestore().collection("posts")
            let users = Firestore.firestore().collection("users")
            let document = posts.document()
            let postID = document.documentID
            let postData: [String: Any] = [
                "imageURL": photo.imageURL,
                "text": postText,
                "creatorID": photo.creatorID,
                "createdTime": Timestamp(),
                "cardID": photo.cardID,
                "photoIDArray": [photo.id],
                "isPrivate": UserDefaults.standard.bool(forKey: "privacyStatus"),
                "likerIDArray": [],
                "id": postID,
                "commentArray": []
            ]
            document.setData(postData) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    print("Post published successfully!")
                    let userDocument = users.whereField("id", isEqualTo: self.photo.creatorID)
                    userDocument.addSnapshotListener { snapshot, error in
                        if let error = error {
                            promise(.failure(error))
                        }
                        guard let documents = snapshot?.documents else {
                            promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid instance"])))
                            return
                        }
                        for document in documents {
                            document.reference.updateData([
                                "postIDArray": FieldValue.arrayUnion([postID])
                            ]) { error in
                                if let error = error {
                                    promise(.failure(error))
                                } else {
                                    promise(.success(()))
                                }
                            }
                        }
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in

            self?.isLoading = false
            if case .failure(let error) = completion {
                           self?.error = error
                       }
        } receiveValue: { [weak self] _ in
            self?.onDismiss?()
        }
        .store(in: &cancellables)
    }
}

struct TextInputView: View {
    @StateObject private var viewModel: TextInputViewModel
    @Binding var path: [FeedDestination]
    @Environment(\.presentationMode) var presentationMode

    init(photo: Photo, path: Binding<[FeedDestination]>, onDismiss: (() -> Void)?) {
        _viewModel = StateObject(wrappedValue: TextInputViewModel(photo: photo, onDismiss: onDismiss))
        self._path = path
    }
    var body: some View {
        VStack {
            KFImage(URL(string: viewModel.photo.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .padding()

            ZStack(alignment: .topLeading) {
                if viewModel.postText.isEmpty {
                    Text("Enter your text here...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $viewModel.postText)
                    .frame(height: 200)
                    .cornerRadius(20)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1)
                    )

            }
            .padding()
            Button(action: {
                viewModel.publishPost()
                path.removeAll()
            }) {

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Publish")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(10)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.isLoading)
            .padding()
        }
        .navigationTitle("Add Post")
        .background(
            Color.black
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
        )
        .alert(isPresented: Binding(
                    get: { viewModel.error != nil },
                    set: { if !$0 { viewModel.clearError() } }
        )) {
            Alert( title: Text("Error"),
                   message: Text(viewModel.error?.localizedDescription ?? "Unknown error"),
                   dismissButton: .default(Text("OK")))
        }
    }
}
struct TextInputView2: View {
    @State private var postText: String = ""
    var photo: Photo
    var onDismiss: (() -> Void)?
    @Binding var path: [FeedDestination]
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        VStack {
            KFImage(URL(string: photo.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 300, height: 300)
                .padding()

            ZStack(alignment: .topLeading) {
                if postText.isEmpty {
                    Text("Enter your text here...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $postText)
                    .frame(height: 200)
                    .cornerRadius(20)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 1)
                    )

            }
            .padding()
            Button(action: {
                publishPost()
            }) {
                Text("Publish")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
        .navigationTitle("Add Post")
        .background(
            Color.black
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
        )
    }
    func publishPost() {
        let db = Firestore.firestore()
        let posts = Firestore.firestore().collection("posts")
        let users = Firestore.firestore().collection("users")
        let document = posts.document()
        let postID = document.documentID
        let postData: [String: Any] = [
            "imageURL": photo.imageURL,
            "text": postText,
            "creatorID": photo.creatorID,
            "createdTime": Timestamp(),
            "cardID": photo.cardID,
            "photoIDArray": [photo.id],
            "isPrivate": UserDefaults.standard.bool(forKey: "privacyStatus"),
            "likerIDArray": [],
            "id": postID,
            "commentArray": []
        ]
        document.setData(postData) { error in
            if let error = error {
                print("Error publishing post: \(error)")
            } else {
                print("Post published successfully!")
                let userDocument = users.whereField("id", isEqualTo: photo.creatorID)
                userDocument.addSnapshotListener { snapshot, error in
                    if let error = error {
                        print(error)
                    }
                    guard let documents = snapshot?.documents else {
                        print("No posts found.")
                        return
                    }
                    for document in documents {
                        document.reference.updateData([
                            "postIDArray": FieldValue.arrayUnion([postID])
                        ]) { error in
                            if let error = error {
                                print("Error updating user's postIDArray: \(error)")
                            } else {
                                print("User's postIDArray updated successfully!")
                            }
                        }
                    }
                }
                onDismiss?()
                path.removeAll()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
