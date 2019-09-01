//
//  DDAbstractLogger+ivar.h
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDAbstractLogger (ivar)

- (nullable id <DDLogFormatter>)ddlgl_logFormatter;
- (dispatch_queue_t)ddlgl_loggerQueue;

@end

NS_ASSUME_NONNULL_END
