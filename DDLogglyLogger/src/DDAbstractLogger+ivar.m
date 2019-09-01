//
//  DDAbstractLogger+ivar.m
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

#import "DDAbstractLogger+ivar.h"

@implementation DDAbstractLogger (ivar)

- (id <DDLogFormatter>)ddlgl_logFormatter
{
    return self->_logFormatter;
}

- (dispatch_queue_t)ddlgl_loggerQueue
{
    return self->_loggerQueue;
}

@end
