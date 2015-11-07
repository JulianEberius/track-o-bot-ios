//
//  AppDelegate.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.windows.first
        // Override point for customization after application launch.
        self.window?.tintColor = UIColor(red:0.52, green:0.35, blue:0.28, alpha:1.0)
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        guard let user = TrackOBot.instance.readTrackOBotAccountDataFile(url) else {
            let viewController = app.topViewController() as! TrackOBotViewController

            let alert = UIAlertController.init(title: "Importing credentials failed", message: "The selected credentials file could not be imported.", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(okAction)
            viewController.presentViewController(alert, animated: true, completion:
                nil)
            return false
        }
        
        TrackOBot.instance.storeUser(user)
        
        TrackOBot.instance.getResults({
            (result) -> Void in
            let viewController = app.topViewController() as! TrackOBotViewController
            switch result {
            case .Success(_):
                let alert = UIAlertController.init(title: "NIIICE", message: "Login, like, totally worked", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.Default, handler: {
                    (a:UIAlertAction) -> Void in
                    viewController.newCredentialsAdded(user)
                })
                alert.addAction(okAction)
                viewController.presentViewController(alert, animated: true, completion: nil)
                
                break
            case .Failure(let err):
                switch err {
                case .LoginFaild(_):
                    let alert = UIAlertController.init(title: "Login failed", message: "Login failed: \(err)", preferredStyle: UIAlertControllerStyle.Alert)
                    let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
                    alert.addAction(okAction)
                    viewController.presentViewController(alert, animated: true, completion: nil)
                    break
                default:
                    print("what!!")
                }
            }
        })
        return true
    }
    
}

extension UIApplication {
    func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
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

