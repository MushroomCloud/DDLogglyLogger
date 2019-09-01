//
//  LogglyFormatter.swift
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

import CocoaLumberjack
import Foundation

@objc
public protocol LogglyFieldDataSource
{
    func additionalLogFieldsFor(message: DDLogMessage) -> [String: String]
}

public class LogglyFormatter: NSObject, DDLogFormatter
{
    let dateFormatter: DateFormatter
    /// Loggly's batch API does not support \n. All characters in the log
    /// will be replaced with this character
    let newlineCharacter: String
    let fieldDataSource: LogglyFieldDataSource?
    
    public static var defaultDateFormatter: DateFormatter
    {
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        dateFormatter.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        dateFormatter.locale = Locale(identifier: "en_GB")
        return dateFormatter
    }
    
    public init(dateFormatter: DateFormatter? = nil, newlineCharacter: String = " <br> ", fieldDataSource: LogglyFieldDataSource? = nil)
    {
        self.dateFormatter = dateFormatter ?? LogglyFormatter.defaultDateFormatter
        self.newlineCharacter = newlineCharacter
        self.fieldDataSource = fieldDataSource
    }
    
    public func format(message logMessage: DDLogMessage) -> String?
    {
        var fields: [String: String] = self.fieldDataSource?.additionalLogFieldsFor(message: logMessage) ?? [:]
        fields["timestamp"] = self.dateFormatter.string(from: logMessage.timestamp)
        fields["log_level"] = self.logLevelFor(flag: logMessage.flag)
        fields["message"] = logMessage.message.replacingOccurrences(of: "\n", with: self.newlineCharacter)
        fields["file"] = (logMessage.file as NSString).lastPathComponent
        fields["function"] = logMessage.function ?? "unknown"
        fields["line_number"] = "\(logMessage.line)"
        if let tag = logMessage.tag as? String
        {
            fields["log_tag"] = tag.replacingOccurrences(of: "\n", with: self.newlineCharacter)
        }
        let components = fields.map({ "\"\($0)\":\"\($1)\"" }).joined(separator: ",")
        return "{\(components)}"
    }
    
    private func logLevelFor(flag: DDLogFlag) -> String
    {
        switch flag
        {
        case DDLogFlag.error: return "error"
        case DDLogFlag.warning: return "warning"
        case DDLogFlag.info: return "info"
        case DDLogFlag.debug: return "debug"
        case DDLogFlag.verbose: return "verbose"
        default: return "unknown[\(flag)]"
        }
    }
}

/// A concrete LogglyFieldDataSource implementation that uses a block to provide the
/// additional fields.
public class LogglyBlockFieldDataSource: NSObject, LogglyFieldDataSource
{
    private let closure: (DDLogMessage) -> [String: String]
    
    init(_ closure: @escaping (DDLogMessage) -> [String: String])
    {
        self.closure = closure
    }
    
    public func additionalLogFieldsFor(message: DDLogMessage) -> [String : String]
    {
        return self.closure(message)
    }
}
