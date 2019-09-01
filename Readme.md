# DDLogglyLogger

A custom [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) logger implementation that uploads received logs to [Loggly](https://www.loggly.com/).

The logs are cached in a local database before uploading to ensure all logs are uploaded (the log entries are only deleted once they have successfully been uploaded).