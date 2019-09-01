//
//  ViewController.swift
//  Example Logger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

import CocoaLumberjack
import DDLogglyLogger
import UIKit

class ViewController: UIViewController
{
    var infoCount = 0
    var warningCount = 0
    var errorCount = 0
    
    @IBAction func logInfo(_ sender: Any)
    {
        self.infoCount += 1
        DDLogInfo("Info log number \(self.infoCount)")
    }
    
    @IBAction func logWarning(_ sender: Any)
    {
        self.warningCount += 1
        DDLogWarn("Warning log number \(self.warningCount)")
    }
    
    @IBAction func logError(_ sender: Any)
    {
        self.errorCount += 1
        DDLogError("Error log number \(self.errorCount)")
    }
}

