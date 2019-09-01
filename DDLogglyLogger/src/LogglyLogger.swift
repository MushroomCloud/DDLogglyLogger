//
//  LogglyLogger.swift
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

import CocoaLumberjack
import Foundation

/// This logger will first write the logs to a SQLite database when saving, and then begin a
/// network request to upload the logs to Loggly. Once the logs have been uploaded, they are
/// deleted from the database.
public class LogglyLogger: DDAbstractDatabaseLogger
{
    public let apiKey: String
    public let tags: [String]
    
    private let urlSession: URLSession
    
    // This must only be modified on the internal logger queue
    private var bufferedMessages: [String]
    // This must only be modified on the internal logger queue
    private var logProcessingInProgress: Bool
    
    public init(apiKey: String, tags: [String] = [])
    {
        self.apiKey = apiKey
        self.tags = tags.count > 0 ? tags : LogglyLogger.defaultTags
        self.bufferedMessages = []
        self.logProcessingInProgress = false
        
        let sessionConfig = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: sessionConfig)
        
        super.init()
        // Disable automatic deletions, the log entries are deleted after upload
        self.maxAge = 0
        self.deleteInterval = 0
        self.bufferedMessages.reserveCapacity(Int(self.ddlgl_saveThreshold()))
    }
    
    @objc
    public func db_log(_ message: DDLogMessage) -> Bool
    {
        assert(self.isOnInternalLoggerQueue)
        
        let messageText = self.ddlgl_logFormatter()?.format(message: message) ?? message.message
        self.bufferedMessages.append(messageText)
        return true
    }
    
    @objc
    public func db_save()
    {
        assert(self.isOnInternalLoggerQueue)
        
        if self.logProcessingInProgress
        {
            return
        }
        self.logProcessingInProgress = true
        
        var database: LogglyLogDatabase
        do
        {
            let path = self.databasePath
            database = try LogglyLogDatabase(path: path)
        }
        catch
        {
            NSLog("DDLogglyLogger: Unable to create the database. \(error.localizedDescription)")
            return
        }
        self.saveAndClearBufferedLogEntries(database)
        self.uploadRemainingLogs(database, completion:
        {
            [weak self] (error: Error?) -> () in
            if let error = error
            {
                NSLog("DDLogglyLogger: Unable to upload some logs. \(error.localizedDescription)")
            }
            guard let `self` = self else { return }
            self.performOnLoggerQueueAsync {
                self.logProcessingInProgress = false
            }
        })
    }
    
    private static var defaultTags: [String]
    {
        return [Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? "app-logger"]
    }
    
    private var databasePath: String
    {
        let dir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        return (dir as NSString).appendingPathComponent("Logs/DDLogglyLogger/logs.sqlite")
    }
    
    private func saveAndClearBufferedLogEntries(_ database: LogglyLogDatabase)
    {
        if self.bufferedMessages.count == 0 { return }
        do
        {
            try database.addLogEntriesWith(logs: self.bufferedMessages)
            self.bufferedMessages = []
            self.bufferedMessages.reserveCapacity(Int(self.ddlgl_saveThreshold()))
        }
        catch
        {
            NSLog("DDLogglyLogger: Unable to save buffered logs to database. \(error.localizedDescription)")
        }
    }
    
    /// Break the logs up into batches, and upload and delete each batch one at a time
    private func uploadRemainingLogs(_ database: LogglyLogDatabase, completion: @escaping (Error?) -> ())
    {
        var batchData = Data()
        var recordsToProcess: [LogglyLogDatabase.Record] = []
        
        do
        {
            let dataSizeLimit = LogglyAPI.maximumBatchDataSize
            let readingBatchSize = 1000
            
            // Loggly uses \n to delimit log events
            let recordDelimiter = "\n".data(using: String.Encoding.utf8)!
            
            while batchData.count < dataSizeLimit
            {
                let readingBatch = try database.queryRecords(afterRecord: recordsToProcess.last, limit: readingBatchSize)
                if readingBatch.count == 0
                {
                    // No more database log entries to process
                    break
                }
                for record in readingBatch
                {
                    guard let recordData = record.text.data(using: String.Encoding.utf8) else { continue }
                    if batchData.count + recordDelimiter.count + recordData.count > dataSizeLimit
                    {
                        break
                    }
                    batchData.append(recordDelimiter)
                    batchData.append(recordData)
                    recordsToProcess.append(record)
                }
            }
        }
        catch
        {
            completion(error)
            return
        }
        
        if recordsToProcess.count == 0
        {
            completion(nil)
            return
        }
        self.uploadBatchLog(data: batchData, completion:
        {
            (error: Error?) in
            if let error = error
            {
                completion(error)
            }
            // capture self strongly to keep the instance alive until the
            // operation completes. When it does, it can then delete the
            // processed records
            self.performOnLoggerQueueAsync
            {
                if let lastRecord = recordsToProcess.last
                {
                    do
                    {
                        try database.deleteAllRecordsUpTo(id: lastRecord.id)
                    }
                    catch
                    {
                        completion(error)
                    }
                }
                self.uploadRemainingLogs(database, completion: completion)
            }
        })
    }
    
    private func uploadBatchLog(data: Data, completion: @escaping (Error?) -> ())
    {
        let url = LogglyAPI.apiURLFor(apiKey: self.apiKey, tags: self.tags)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        request.httpMethod = "POST"
        request.httpBody = data
        self.urlSession.dataTask(with: request)
        {
            (_, response: URLResponse?, error: Error?) in
            if let error = error
            {
                completion(error)
            }
            else if let httpResonse = response as? HTTPURLResponse,
                    httpResonse.statusCode < 200 || httpResonse.statusCode >= 300
            {
                completion(LogglyAPI.Error.invalidServerResponse(httpResonse.statusCode))
            }
            completion(nil)
        }
        .resume()
    }
    
    private func performOnLoggerQueueAsync(_ execute: @escaping () -> ())
    {
        if self.isOnInternalLoggerQueue
        {
            execute()
        }
        else
        {
            self.ddlgl_loggerQueue().async(execute: execute)
        }
    }
}
