//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Fatimah on 06/04/1441 AH.
//  Copyright © 1441 Fatimah. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        DataController.shared.load()
        
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        try? DataController.shared.viewContext.save()
        
    }

}

