//
//  OSLog.swift
//  Bouncer
//
//  Created by Daniel on 12/09/22.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs message filter related messages
    static let messageFilterLog = OSLog(subsystem: subsystem, category: "messageFilter")
    
    /// Logs Errors
    static let errorLog = OSLog(subsystem: subsystem, category: "errorLog")
}
