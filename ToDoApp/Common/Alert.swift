//
//  Alert.swift
//  TownsCup
//
//  Created by Lavanya on 26/05/19.
//  Copyright © 2019 Scrachie. All rights reserved.
//

import UIKit

class AlertGlobal {
    
    
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
    
    // MARK: Alert methods
    class func showOkAlert(title: String = "", message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
//        if let viewC = kAppDelegate.window?.rootViewController {
//            viewC.present(alertController, animated: true, completion: nil)
//        }
        
        if let topViewController: UIViewController = Helper.topMostViewController(rootViewController: Helper.rootViewController()) {
            topViewController.present(alertController, animated: true, completion: nil)
        } else if let viewC = UIApplication.shared.delegate?.window??.rootViewController {
            viewC.present(alertController, animated: true, completion: nil)
        }
    }
    
    class func showOkAlertWithCallBack(title: String = "", message: String,okButtonTitle:String = "OK" ,completeion_: @escaping (_ compl:Bool)->())
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: okButtonTitle, style: .cancel, handler: { (action:UIAlertAction!) -> Void in
            completeion_(true) //returns true in callback to perform action on last screen
        })
        alertController.addAction(cancelAction)
        if let topViewController: UIViewController = Helper.topMostViewController(rootViewController: Helper.rootViewController()) {
            topViewController.present(alertController, animated: true, completion: nil)
        } else if let viewC = UIApplication.shared.delegate?.window??.rootViewController {
            viewC.present(alertController, animated: true, completion: nil)
        }
    }
    
    class func showAlert(title: String? = nil, message: String? = nil, style: UIAlertController.Style = .alert, actions: UIAlertAction...) {
        
        let topViewController: UIViewController? = Helper.topMostViewController(rootViewController: Helper.rootViewController())
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        if !actions.isEmpty {
            for action in actions {
                alertController.addAction(action)
            }
        } else {
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
        }
        topViewController?.present(alertController, animated: true, completion: nil)
    }
    
    class func showAlertWithAction(title: String?, message: String?, style: UIAlertController.Style, actionTitles:[String?], action:((UIAlertAction) -> Void)?) {
        
        showAlertWithActionWithCancel(title: title, message: message, style: style, actionTitles: actionTitles, showCancel: false, deleteTitle: nil, action: action)
    }
    
    class func showAlertWithActionWithCancel(title: String?, message: String?, style: UIAlertController.Style, actionTitles:[String?], showCancel:Bool, deleteTitle: String? ,_ viewC: UIViewController? = nil, action:((UIAlertAction) -> Void)?) {
        
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        if deleteTitle != nil {
            let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive, handler: action)
            alertController.addAction(deleteAction)
        }
        for (_, title) in actionTitles.enumerated() {
            let action = UIAlertAction(title: title, style: .default, handler: action)
            alertController.addAction(action)
        }
        
        if showCancel {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
        }
        if let viewController = viewC {
            
            viewController.present(alertController, animated: true, completion: nil)
            
        } else {
            let topViewController: UIViewController? = Helper.topMostViewController(rootViewController: Helper.rootViewController())
            topViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    class func showOkAlertWithViewcontrollerAndCallBack(title: String = "", message: String, viewController: UIViewController? = nil ,completeion_: @escaping (_ compl:Bool)->())
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: { (action:UIAlertAction!) -> Void in
            completeion_(true) //returns true in callback to perform action on last screen
        })
        alertController.addAction(cancelAction)
        if let topViewController: UIViewController = Helper.topMostViewController(rootViewController: Helper.rootViewController()) {
            topViewController.present(alertController, animated: true, completion: nil)
        } else if let viewC = viewController {
            viewC.present(alertController, animated: true, completion: nil)
        }
    }

}

