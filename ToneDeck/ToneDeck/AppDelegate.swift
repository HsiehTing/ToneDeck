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

           

            return true
        }

}
