//
//  CrashHandler.h
//  RunLoopDemo04
//
//  Created by Harvey on 2016/12/15.
//  Copyright © 2016年 Haley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CrashHandler : NSObject
{
    BOOL ignore;
}

+ (instancetype)sharedInstance;

@end


