//
//  Logger.swift
//  SitumMappingTool
//
//  Created by Adrián Rodríguez on 15/05/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation
import os

@available(iOS 10.0, *)
extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier!
    /// default category
    static let defaultCategory = OSLog(subsystem: subsystem, category: "SitumMappingTool")
}

class Logger {
    
    public static func logInfoMessage(_ message: String) {
        if #available(iOS 10.0, *) {
            self.logMessage(message, withCategory: OSLog.defaultCategory, withLogLevel: .info)
        } else {
            print(message)
        }
    }
    
    public static func logDebugMessage(_ message: String) {
        if #available(iOS 10.0, *) {
            self.logMessage(message, withCategory: OSLog.defaultCategory, withLogLevel: .debug)
        } else {
            print(message)
        }
    }
    
    public static func logErrorMessage(_ message: String) {
        if #available(iOS 10.0, *) {
            self.logMessage(message, withCategory: OSLog.defaultCategory, withLogLevel: .error)
        } else {
            print(message)
        }
    }
    
    @available(iOS 10.0, *)
    static func logMessage(_ message: String, withCategory category: OSLog, withLogLevel level: OSLogType) {
        os_log("%{PUBLIC}@", log: category, type: level, message)
    }
}
