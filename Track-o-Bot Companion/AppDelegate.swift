//
//  AppDelegate.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
        // Override point for customization after application launch.
//        self.window?.tintColor = UIColor(red:0.52, green:0.35, blue:0.28, alpha:1.0)
        self.window?.tintColor = UIColor(red:1.00, green:0.0, blue:0.0, alpha:1.0)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        guard let user = TrackOBot.instance.readTrackOBotAccountDataFile(url) else {
            let viewController = app.topViewController() as! TrackOBotViewController

            let alert = UIAlertController.init(title: "Importing credentials failed", message: "The selected credentials file could not be imported.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(okAction)
            viewController.present(alert, animated: true, completion:
                nil)
            return false
        }

        TrackOBot.instance.storeUser(user)

        TrackOBot.instance.getResults(0, onComplete: {
            (result) -> Void in
            let viewController = app.topViewController() as! TrackOBotViewController
            switch result {
            case .success(_):
                viewController.newCredentialsAdded(user)
                break
            case .failure(let err):
                switch err {
                case .networkError(_):
                    self.alert(viewController, title: "Login failed", message: "Could not connect to TrackOBot.com. Check your internet connection, and whether https://trackobot.com is available.")
                    break
                case .loginFailed(let errMsg):
                    self.alert(viewController, title: "Login failed", message: "Sorry, the login failed. Check if you used a valid credential file. Error: \(errMsg)")
                    break
                default:
                    self.alert(viewController, title: "Login error", message: "Sorry, the login failed for mysterious reasons. If the error persists, please contact trackobot.ios@gmail.com.")
                }
            }
        })
        return true
    }

    func alert(_ viewController: TrackOBotViewController, title: String, message:String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.default, handler:nil)
        alert.addAction(okAction)
        viewController.present(alert, animated: true, completion: nil)
    }

}

extension UIApplication {
    func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

