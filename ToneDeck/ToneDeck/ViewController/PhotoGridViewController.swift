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
    @State private var photosURL = [String]() // 儲存從 Firebase 讀取的照片URL
    @State private var selectedImageURL: String? // 選中的照片 URL
    @State private var isTextInputActive = false // 控制導航至文字輸入頁面
    @State private var selectedPhoto: Photo?
    @StateObject private var firestoreService = FirestoreService() // 用於讀取 Firestore 資料

    var body: some View {
        NavigationView {
            VStack {
                // 上半部分：顯示選中的照片
                if let selectedImageURL = selectedImageURL, let url = URL(string: selectedImageURL) {
                    KFImage(url)
                        .resizable()
                        .padding()
                        .scaledToFill()
                        .frame(height: 500)
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
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .scaledToFill()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Photo Grid")
            .navigationBarItems(trailing: Button("Next") {
                // 點擊 "Next" 導航到文字輸入頁面
                if let selectedPhoto = selectedPhoto {
                    isTextInputActive = true // Trigger the navigation when a photo is selected
                }
            })
            .onAppear {
                firestoreService.fetchPhotos() // Fetch photos when view appears
            }
            .background(
                Group {
                    if let unwrappedPhoto = selectedPhoto {
                        NavigationLink(
                            destination: TextInputView(photo: unwrappedPhoto),
                            isActive: $isTextInputActive,
                            label: { EmptyView() }
                        )
                    } else {
                        EmptyView() // 當沒有選中照片時顯示空視圖
                    }
                }
            )
        }
    }
}
