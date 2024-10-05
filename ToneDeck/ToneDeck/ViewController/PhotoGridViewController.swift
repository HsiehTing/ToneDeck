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
    @State private var photosURL = [String]() // 儲存從 Firebase 讀取的照片URL
    @State private var selectedImageURL: String? // 選中的照片 URL
    @State private var isTextInputActive = false // 控制導航至文字輸入頁面
    @State private var selectedPhoto: Photo?
    @StateObject private var firestoreService = FirestoreService() // 用於讀取 Firestore 資料
    @Environment(\.presentationMode) var presentationMode
    @State private var isFeedViewActive = false

    var body: some View {
        NavigationView {
            VStack {
                // 上半部分：顯示選中的照片
                if let selectedImageURL = selectedImageURL, let url = URL(string: selectedImageURL) {
                    KFImage(url)
                        .resizable()
                        .padding()
                        .scaledToFill()
                        .frame(height: 300)
                } else {
                    Text("Select an Image")
                        .font(.headline)
                        .padding()
                }

                // 下半部分：顯示照片網格
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(firestoreService.photos.sorted(by: {  ($0.createdTime.dateValue()) > ($1.createdTime.dateValue())  }), id: \.id) { photo in
                            Button(action: {
                                selectedPhoto = photo
                                selectedImageURL = photo.imageURL // Set the selected image URL
                            }) {
                                KFImage(URL(string: photo.imageURL))
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipped()

                                    .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Grid")
            .navigationBarItems(trailing: Button("Next") {
                // 點擊 "Next" 導航到文字輸入頁面
                if let selectedPhoto = selectedPhoto {
                    isTextInputActive = true
                }

            })
            .onAppear {
                firestoreService.fetchPhotos() // Fetch photos when view appears
            }
            .background(
                Group {
                    if let unwrappedPhoto = selectedPhoto {
                        NavigationLink(

                            destination: TextInputView(photo: selectedPhoto ?? Photo(id: "", imageURL: "", cardID: "", creatorID: "", createdTime: Timestamp()), onDismiss: {
                                // 在 TextInputView 結束後導航回 FeedView
                                isFeedViewActive = true
                            }, path: $path),
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
                        EmptyView() // 當沒有選中照片時顯示空視圖
                    }
                }
            )
        }
    }
}
#Preview {
    FeedView()
}
