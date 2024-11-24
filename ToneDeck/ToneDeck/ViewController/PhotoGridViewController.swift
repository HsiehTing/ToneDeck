//
//  PhotoGridViewController.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/16.
//

import SwiftUI
import FirebaseFirestore
import Kingfisher

struct PhotoGridView: View {
    @Binding var path: [FeedDestination]
    @State private var photosURL = [String]()
    @State private var selectedImageURL: String?
    @State private var isTextInputActive = false
    @State private var selectedPhoto: Photo?
    @StateObject private var firestoreService = FirestoreService()
    @Environment(\.presentationMode) var presentationMode
    @State private var isFeedViewActive = false

    var body: some View {
        NavigationView {
            VStack {
                if let selectedImageURL = selectedImageURL, let url = URL(string: selectedImageURL) {
                    KFImage(url)
                        .resizable()
                        .padding()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
                } else {
                    Text("Select an Image")
                        .font(.headline)
                        .padding()
                }
                if firestoreService.photos.count > 0 {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(firestoreService.photos.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  }), id: \.id) { photo in
                                Button(action: {
                                    selectedPhoto = photo
                                    selectedImageURL = photo.imageURL
                                }) {
                                    KFImage(URL(string: photo.imageURL))
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()

                                        .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    Text("No photots available, import a photo in Cards page!")
                        .font(.headline)
                        .padding()
                    Spacer()
                }

            }
            .navigationTitle("Photo Grid")
            .navigationBarItems(trailing: Button("Next") {
                if let selectedPhoto = selectedPhoto {
                    isTextInputActive = true
                }

            })
            .onAppear {
                firestoreService.fetchPhotos()
            }
            .background(
                Group {
                    if let unwrappedPhoto = selectedPhoto {
                        NavigationLink(

                            destination: TextInputView(photo: selectedPhoto ?? Photo(id: "", imageURL: "", cardID: "", creatorID: "", createdTime: Timestamp()), path: $path, onDismiss: {
                                
                                isFeedViewActive = true
                            }),
                            isActive: $isTextInputActive,
                            label: { EmptyView() }
                        )
                        NavigationLink(
                            destination: FeedView(),
                            isActive: $isFeedViewActive,
                            label: {
                                EmptyView()
                            }
                        )
                    } else {
                        EmptyView() 
                    }
                }
            )
        }
    }
}
#Preview {
    FeedView()
}
