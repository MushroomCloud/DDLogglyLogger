//
//  LogglyLogDatabase.swift
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

import Foundation
import SQLite3

internal class LogglyLogDatabase
{
    enum Error: Swift.Error
    {
        case couldNotOpen(Int32, String?)
        case couldNotCreateTable(Int32, String?)
        case couldNotPrepareStatement(Int32, String?)
        case couldNotBindParameter(Int32, String?)
        case couldNotExecuteStatement(Int32, String?)
        case couldNotTransact(Int32, String?)
    }
    
    struct Record
    {
        let id: Int64
        let text: String
    }
    
    private var db: OpaquePointer?
    private var lastDatabaseErrorMessage: String?
    {
        if let errorPointer = sqlite3_errmsg(self.db)
        {
            return String(cString: errorPointer)
        }
        return nil
    }
    
    internal init(path: String) throws
    {
        try self.openDatabaseAt(path: path)
        try self.createLogEntryTable()
    }
    
    deinit
    {
        sqlite3_close(self.db)
    }
    
    internal func addLogEntriesWith(logs: [String]) throws
    {
        let command = "insert into LOG_ENTRY (log_text) values (?1);"
        var statement: OpaquePointer? = try prepareStatementFor(command: command)
        defer { sqlite3_finalize(statement) }
        
        let beginCommand = "begin;"
        let rollBackCommand = "rollback;"
        let commitCommand = "commit"
        
        var errorMessage: UnsafeMutablePointer<CChar>? = nil
        var result = sqlite3_exec(self.db, beginCommand, nil, nil, &errorMessage)
        guard result == SQLITE_OK else
        {
            throw Error.couldNotTransact(result, errorMessage.map { String(cString: $0) })
        }
        var didFinish = false
        defer
        {
            if !didFinish
            {
                result = sqlite3_exec(self.db, rollBackCommand, nil, nil, nil)
                if result != SQLITE_OK
                {
                    print("Could not roll back the transaction after failure (\(result)). \(self.lastDatabaseErrorMessage ?? "An unknown error occurred.")")
                }
            }
        }
        
        for logText in logs
        {
            let text = logText as NSString
            result = sqlite3_bind_text(statement, 1, text.utf8String, -1, nil)
            guard result == SQLITE_OK else
            {
                throw Error.couldNotBindParameter(result, self.lastDatabaseErrorMessage)
            }
            result = sqlite3_step(statement)
            guard result == SQLITE_DONE else
            {
                throw Error.couldNotExecuteStatement(result, self.lastDatabaseErrorMessage)
            }
            sqlite3_reset(statement)
        }
        
        errorMessage = nil
        result = sqlite3_exec(self.db, commitCommand, nil, nil, &errorMessage)
        if result != SQLITE_OK
        {
            throw Error.couldNotTransact(result, errorMessage.map { String(cString: $0) })
        }
        didFinish = true
    }
    
    internal func queryRecordCount() throws -> Int64
    {
        let command = "select count(*) from LOG_ENTRY"
        var statement = try prepareStatementFor(command: command)
        defer { sqlite3_finalize(statement) }
        
        var count: Int64 = 0
        if (sqlite3_step(statement) == SQLITE_ROW)
        {
            count = sqlite3_column_int64(statement, 0)
        }
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW
        {
            result = sqlite3_step(statement)
        }
        if result != SQLITE_DONE
        {
            throw Error.couldNotExecuteStatement(result, self.lastDatabaseErrorMessage)
        }
        return count
    }
    
    internal func queryRecords(afterRecord: Record?, limit: Int) throws -> [Record]
    {
        let command: String
        if let afterRecord = afterRecord
        {
            command = "select * from LOG_ENTRY where id > \(afterRecord.id) order by id asc limit \(limit)"
        }
        else
        {
            command = "select * from LOG_ENTRY order by id asc limit \(limit)"
        }
        
        var statement = try prepareStatementFor(command: command)
        defer { sqlite3_finalize(statement) }
        
        let recordCount = try self.queryRecordCount()
        var records: [Record] = []
        records.reserveCapacity(Int(recordCount))
        
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW
        {
            let id = sqlite3_column_int64(statement, 0)
            if let text = sqlite3_column_text(statement, 1)
            {
                records.append(Record(id: id, text: String(cString: text)))
            }
            result = sqlite3_step(statement)
        }
        if result != SQLITE_DONE
        {
            throw Error.couldNotExecuteStatement(result, self.lastDatabaseErrorMessage)
        }
        return records
    }
    
    // Deletes all records with id <= the given id
    internal func deleteAllRecordsUpTo(id: Int64) throws
    {
        let command = "delete from LOG_ENTRY where id <= \(id)"
        var statement = try prepareStatementFor(command: command)
        defer { sqlite3_finalize(statement) }
        
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else
        {
            throw Error.couldNotExecuteStatement(result, self.lastDatabaseErrorMessage)
        }
    }
    
    private func openDatabaseAt(path: String) throws
    {
        let fileManager = FileManager.default
        let dir = (path as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: dir)
        {
            try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }
        let result = sqlite3_open(path, &self.db)
        if result != SQLITE_OK
        {
            throw Error.couldNotOpen(result, self.lastDatabaseErrorMessage)
        }
    }
    
    private func createLogEntryTable() throws
    {
        let command = "create table if not exists LOG_ENTRY(id integer primary key, log_text text not null)"
        var statement = try prepareStatementFor(command: command)
        defer { sqlite3_finalize(statement) }
        
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else
        {
            throw Error.couldNotCreateTable(result, self.lastDatabaseErrorMessage)
        }
    }
    
    private func prepareStatementFor(command: String) throws -> OpaquePointer?
    {
        var statement: OpaquePointer? = nil
        let result = sqlite3_prepare_v2(self.db, command, -1, &statement, nil)
        guard result == SQLITE_OK else
        {
            throw Error.couldNotPrepareStatement(result, self.lastDatabaseErrorMessage)
        }
        return statement
    }
}
