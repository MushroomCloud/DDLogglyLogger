//
//  DDAbstractDatabaseLogger+ivar.m
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

#import "DDAbstractDatabaseLogger+ivar.h"

@implementation DDAbstractDatabaseLogger (ivar)

- (NSUInteger)ddlgl_saveThreshold
{
    return self->_saveThreshold;
}

@end
