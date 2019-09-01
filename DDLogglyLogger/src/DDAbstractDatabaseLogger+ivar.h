//
//  DDAbstractDatabaseLogger+ivar.h
//  DDLogglyLogger
//
//  Created by Rayman Rosevear on 2019/09/01.
//  Copyright © 2019 Mushroom Cloud. All rights reserved.
//

#import <CocoaLumberjack/CocoaLumberjack.h>

NS_ASSUME_NONNULL_BEGIN

@interface DDAbstractDatabaseLogger (ivar)

- (NSUInteger)ddlgl_saveThreshold;

@end

NS_ASSUME_NONNULL_END
