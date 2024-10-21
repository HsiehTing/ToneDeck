
## Features

**Add Card**

When you add a card, filter values related to the card are calculated and saved to cloud storage.

**Select Photo for Card**

You can upload a photo from your library or take a new one with the in-app camera.

<img src="https://github.com/user-attachments/assets/1719a990-e44e-465f-ad8c-6498533f6030" width="350"/>

**Apply Card to Photo**

The selected photo will be processed, and filter values from the card will be compared and adjusted. The filter settings will then be applied to make your photo look like the card's style.

<img src="https://github.com/user-attachments/assets/c1b7f58e-2d96-4bf0-a2d7-5dd0259d53f0" width="350"/>

**Apply Card to Camera**

You can also apply a card’s filter directly to the camera view, allowing you to see the effect in real-time as you take a photo.

<img src="https://github.com/user-attachments/assets/c6ca2cc8-ba40-4710-a302-d3719c3fb9bb" width="350"/>

**Customize Photo Settings**

After applying a card, you can further adjust brightness, contrast, saturation, hue, and even add a grainy film effect.

<img src="https://github.com/user-attachments/assets/3ca941d2-b1dd-473e-ba7c-9c78633ecb2c" width="350"/>

**Feed Page**

In the Feed, you can share photos publicly or with followers. Each post includes data on which card filter was used.

<img src="https://github.com/user-attachments/assets/89cf6d33-2d5d-4e41-b382-a29d19acab20" width="350"/>

**Search by Card ID**

You can share a card by its ID. Other users can search for and apply the card by entering its ID.

<img src="https://github.com/user-attachments/assets/2a452bc7-0ba6-4dd1-b36c-53cf4d7d307b" width="350"/>

## Techniques

- Built using both SwiftUI and UIKit.

- Created a method to map photo pixels to histogram data.

- Generated filter values (brightness, contrast, saturation, hue, grainy) from histogram data.

- Developed a system to compare and adjust filters between cards and photos.

- Applied various CIFilter effects to photos (brightness, contrast, saturation, hue, grainy).

- Integrated CIFilter effects into the in-app camera.

- Enabled photo library access to select, save, and edit images.

- Added social features like like, comment, and follow.
## Libraries
 - [AlertKit](https://github.com/sparrowcode/AlertKit)
 - [FireBase](https://firebase.google.com/)
  - [IQKeyboardManagerSwift](https://github.com/hackiftekhar/IQKeyboardManager) 
 - [Kingfisher](https://github.com/onevcat/Kingfisher)


## Requirements
- [x] Xcode 13.0
- [x] Swift 5
- [x] iOS 13 or higher
### Release Notes

| Version | Date       | Notes                                                                 |
|---------|------------|-----------------------------------------------------------------------|
| 1.0.1   | 2024.10.13 | Released in App Store.                                                |
| 1.0.2   | 2024.10.14 | Update UI Layout and Initial animation

### Author
**Hsieh Ting** ｜ sting20210@gmail.com
