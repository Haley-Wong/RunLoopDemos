//
//  FluencyMonnitor.m
//  RunLoopDemo03
//
//  Created by Harvey on 2016/12/14.
//  Copyright © 2016年 Haley. All rights reserved.
//

#import "FluencyMonitor.h"

#import <CrashReporter/CrashReporter.h>

@interface FluencyMonitor ()

@property (strong, nonatomic)   NSThread                *monitorThread; /**< 监控线程 */
@property (assign, nonatomic)   CFRunLoopObserverRef    observer;       /**< 观察者 */
@property (assign, nonatomic)   CFRunLoopTimerRef       timer;          /**< 定时器 */

@property (strong, nonatomic)   NSDate                  *startDate;     /**< 开始执行的时间 */
@property (assign, nonatomic)   BOOL                    excuting;       /**< 执行时长 */

@property (assign, nonatomic)   NSTimeInterval          interval  ;     /**< 定时器间隔时间 */
@property (assign, nonatomic)   NSTimeInterval          fault;          /**< 卡顿的阙值 */

@end

@implementation FluencyMonitor

static FluencyMonitor *instance = nil;

+ (instancetype)shareMonitor
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
        instance.monitorThread = [[NSThread alloc] initWithTarget:self selector:@selector(monitorThreadEntryPoint) object:nil];
        [instance.monitorThread start];
    });
    
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

+ (void)monitorThreadEntryPoint
{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"FluencyMonitor"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

/**
 开始监控
 */
- (void)start
{
    [self startWithInterval:1.0 fault:2.0];
}

- (void)startWithInterval:(NSTimeInterval)interval fault:(NSTimeInterval)fault
{
    _interval = interval;
    _fault = fault;
    
    if (_observer) {
        return;
    }
    
    // 1.创建observer
    CFRunLoopObserverContext context = {0,(__bridge void*)self, NULL, NULL, NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                              kCFRunLoopAllActivities,
                                              YES,
                                              0,
                                              &runLoopObserverCallBack,
                                              &context);
    // 2.将observer添加到主线程的RunLoop中
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    // 3.创建一个timer，并添加到子线程的RunLoop中
    [self performSelector:@selector(addTimerToMonitorThread) onThread:self.monitorThread withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}

- (void)addTimerToMonitorThread
{
    if (_timer) {
        return;
    }
    // 创建一个timer
    CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
    CFRunLoopTimerContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
    _timer = CFRunLoopTimerCreate(kCFAllocatorDefault, 0.1, _interval, 0, 0,
                                                   &runLoopTimerCallBack, &context);
    // 添加到子线程的RunLoop中
    CFRunLoopAddTimer(currentRunLoop, _timer, kCFRunLoopCommonModes);
}

- (void)removeTimer
{
    if (_timer) {
        CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
        CFRunLoopRemoveTimer(currentRunLoop, _timer, kCFRunLoopCommonModes);
        CFRelease(_timer);
        _timer = NULL;
    }
}

- (void)stop
{
    if (_observer) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
        CFRelease(_observer);
        _observer = NULL;
    }

    [self performSelector:@selector(removeTimer) onThread:self.monitorThread withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}

- (void)handleStackInfo
{
    NSData *lagData = [[[PLCrashReporter alloc]
                        initWithConfiguration:[[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll]] generateLiveReport];
    PLCrashReport *lagReport = [[PLCrashReport alloc] initWithData:lagData error:NULL];
    NSString *lagReportString = [PLCrashReportTextFormatter stringValueForCrashReport:lagReport withTextFormat:PLCrashReportTextFormatiOS];
    //将字符串上传服务器
    NSLog(@"lag happen, detail below: \n %@",lagReportString);
}


static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    FluencyMonitor *monitor = (__bridge FluencyMonitor*)info;
    NSLog(@"MainRunLoop---%@",[NSThread currentThread]);
    switch (activity) {
        case kCFRunLoopEntry:
            NSLog(@"kCFRunLoopEntry");
            break;
        case kCFRunLoopBeforeTimers:
            NSLog(@"kCFRunLoopBeforeTimers");
            break;
        case kCFRunLoopBeforeSources:
            NSLog(@"kCFRunLoopBeforeSources");
            monitor.startDate = [NSDate date];
            monitor.excuting = YES;
            break;
        case kCFRunLoopBeforeWaiting:
            NSLog(@"kCFRunLoopBeforeWaiting");
            monitor.excuting = NO;
            break;
        case kCFRunLoopAfterWaiting:
            NSLog(@"kCFRunLoopAfterWaiting");
            break;
        case kCFRunLoopExit:
            NSLog(@"kCFRunLoopExit");
            break;
        default:
            break;
    }
}

static void runLoopTimerCallBack(CFRunLoopTimerRef timer, void *info)
{
    FluencyMonitor *monitor = (__bridge FluencyMonitor*)info;
    if (!monitor.excuting) {
        return;
    }
    
    // 如果主线程正在执行任务，并且这一次loop 执行到 现在还没执行完，那就需要计算时间差
    NSTimeInterval excuteTime = [[NSDate date] timeIntervalSinceDate:monitor.startDate];
    NSLog(@"定时器---%@",[NSThread currentThread]);
    NSLog(@"主线程执行了---%f秒",excuteTime);
    
    if (excuteTime >= monitor.fault) {
        NSLog(@"线程卡顿了%f秒",excuteTime);
        [monitor handleStackInfo];
    }
}


@end
