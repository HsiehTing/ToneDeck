//
//  AppDelegate.swift
//  ToneDeck
//
//  Created by 謝霆 on 2024/9/11.
//

import UIKit
import FirebaseCore
import IQKeyboardManagerSwift

class AppDelegate: NSObject, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        IQKeyboardManager.shared.enable = true
        return true
    }
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
            guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                  let url = userActivity.webpageURL else {
                return false
            }

            handleUniversalLink(url: url)

            return true
        }

        func handleUniversalLink(url: URL) {
            print("Received Universal Link: \(url.absoluteString)")

            if url.path == "/applyCard" {
               
                navigateToApplyCard()
            }
        }

        func navigateToApplyCard() {
            // 假设使用 UINavigationController 进行页面导航
            if let rootVC = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
                let applyCardVC = ApplyCardViewController()
                rootVC.pushViewController(applyCardVC, animated: true)
            }
        }
}
