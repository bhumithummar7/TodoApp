//
//  Helper.swift
//
//

import Foundation
import UIKit
class Helper {
    class func getDeviceID() -> String{
        var deviceId: String
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            deviceId = uuid
        } else {
            deviceId = ""
        }
        return deviceId
    }
    
    class func dynamicFontSize(baseSize: CGFloat) -> CGFloat {
            let screenSize = UIScreen.main.bounds.size
            let scaleFactor = min(screenSize.width, screenSize.height) / 393.0 // Assuming a reference width of 375 points
            let scale = baseSize * scaleFactor
            return scale > baseSize ? baseSize : scale
    }
    
    //Date formatting function
    class func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60

        if hours == 0 {
            return String(format: "%d min", minutes)
        } else {
            return String(format: "%d hr %02d min", hours, minutes)
        }
    }

    class func formatString(_ formattedString: String) -> TimeInterval? {
        let components = formattedString.components(separatedBy: CharacterSet.decimalDigits.inverted)

        guard components.count >= 1 else {
            return nil
        }

        if let minutes = Int(components[0]) {
            let totalSeconds = TimeInterval(minutes * 60)
            return totalSeconds
        }

        return nil
    }
    // MARK: - Get root view controller
    class func rootViewController() -> UIViewController {
        return (UIApplication.shared.keyWindow?.rootViewController) ?? UIViewController()
    }
    
    // MARK: - Get topmost view controller
    class func topMostViewController(rootViewController: UIViewController) -> UIViewController? {
        if let navigationController = rootViewController as? UINavigationController {
            return topMostViewController(rootViewController: navigationController.visibleViewController!)
        }
        if let tabBarController = rootViewController as? UITabBarController {
            if let selectedTabBarController = tabBarController.selectedViewController {
                return topMostViewController(rootViewController: selectedTabBarController)
            }
        }
        if let presentedViewController = rootViewController.presentedViewController {
            return topMostViewController(rootViewController: presentedViewController)
        }
        return rootViewController
    }
    
    //MARK: - Get Visible view controller
    class func visibleController() -> UIViewController {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return UIViewController()
    }
}
struct NavigationUtil {
    static func popToRootView(animated: Bool = false) {
        findNavigationController(viewController: UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.rootViewController)?.popToRootViewController(animated: animated)
    }
    
    static func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        
        if let navigationController = viewController as? UITabBarController {
            return findNavigationController(viewController: navigationController.selectedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        for childViewController in viewController.children {
            return findNavigationController(viewController: childViewController)
        }
        
        return nil
    }
}
