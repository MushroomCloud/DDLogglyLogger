//
//  AppDelegate.swift
//  Example Logger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

import CocoaLumberjack
import DDLogglyLogger
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        let logglyLogger = LogglyLogger(apiKey: "")
        logglyLogger.logFormatter = LogglyFormatter()
        logglyLogger.saveThreshold = 10
        
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(logglyLogger)
        return true
    }
}

