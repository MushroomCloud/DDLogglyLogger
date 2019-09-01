//
//  LogglyAPI.swift
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

import Foundation

internal struct LogglyAPI
{
    internal static let maximumBatchDataSize = 5 * 1000 // Loggly has a 5mb batch size limit
    
    static internal func apiURLFor(apiKey: String, tags: [String]) -> URL
    {
        let tagString = tags.joined(separator: ",")
        return URL(string: "https://logs-01.loggly.com/bulk/\(apiKey)/tag/\(tagString)/")!
    }
    
    internal enum Error: Swift.Error
    {
        case invalidServerResponse(Int)
    }
}

extension LogglyAPI.Error: CustomNSError
{
    static var errorDomain: String { return "LogglyAPI.Error" }
    
    var errorCode: Int
    {
        switch self
        {
        case .invalidServerResponse: return 0
        }
    }
    
    var errorUserInfo: [String : Any]
    {
        let description: String
        switch self
        {
        case .invalidServerResponse(let code):
            description = "The server returned an invalid response code (\(code))"
        }
        return [NSLocalizedDescriptionKey: description]
    }
}
