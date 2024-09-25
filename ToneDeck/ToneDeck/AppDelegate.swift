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
            // 检查活动类型是否为浏览网页的活动
            guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
                  let url = userActivity.webpageURL else {
                return false
            }

            // 处理 URL，例如解析路径或参数
            handleUniversalLink(url: url)

            return true
        }

        func handleUniversalLink(url: URL) {
            // 拿到 URL，打印出来查看
            print("Received Universal Link: \(url.absoluteString)")

            // 根据 URL 执行相应操作，例如导航到特定页面
            if url.path == "/applyCard" {
                // 导航到 ApplyCardViewController
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
