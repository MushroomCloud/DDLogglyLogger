//
//  LogglyDatabaseError+CustomNSError.swift
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

import Foundation

extension LogglyLogDatabase.Error: CustomNSError
{
    static var errorDomain: String { return "LogglyLogDatabase.Error" }
    
    /// The error code within the given domain.
    var errorCode: Int
    {
        switch self
        {
        case .couldNotOpen: return 0
        case .couldNotCreateTable: return 1
        case .couldNotPrepareStatement: return 2
        case .couldNotBindParameter: return 3
        case .couldNotExecuteStatement: return 4
        case .couldNotTransact: return 5
        }
    }
    
    /// The user-info dictionary.
    var errorUserInfo: [String : Any]
    {
        let description: String
        switch self
        {
        case .couldNotOpen(let code, let error):
            description = "The database could not be opened (\(code)). \(error ?? "An unknown error occurred."))"
        case .couldNotCreateTable(let code, let error):
            description = "The table could not be created (\(code)). \(error ?? "An unknown error occurred."))"
        case .couldNotPrepareStatement(let code, let error):
            description = "The statement could not be prepared (\(code)). \(error ?? "An unknown error occurred."))"
        case .couldNotBindParameter(let code, let error):
            description = "The parameter parameter binding failed (\(code)). \(error ?? "An unknown error occurred."))"
        case .couldNotExecuteStatement(let code, let error):
            description = "The statement execution failed (\(code)). \(error ?? "An unknown error occurred."))"
        case .couldNotTransact(let code, let error):
            description = "The transaction could not be performed (\(code)). \(error ?? "An unknown error occurred."))"
        }
        return [NSLocalizedDescriptionKey: description]
    }
}
