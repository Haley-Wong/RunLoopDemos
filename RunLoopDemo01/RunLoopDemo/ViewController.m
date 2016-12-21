//
//  ViewController.m
//  RunLoopDemo
//
//  Created by Harvey on 2016/12/1.
//  Copyright © 2016年 Haley. All rights reserved.
//

#import "ViewController.h"
#import "HLThread.h"

@interface ViewController ()

@property (strong, nonatomic)   HLThread            *subThread;  /**< 子线程 */

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //打印与主线程关联的RunLoop，可以查看MainRunLoop中的modes，还可以看到commonItems和各个mode中的items
    CFRunLoopRef runLoopRef = CFRunLoopGetMain();
    CFArrayRef modes = CFRunLoopCopyAllModes(runLoopRef);
    NSLog(@"MainRunLoop中的modes:%@",modes);
    NSLog(@"MainRunLoop对象：%@",runLoopRef);
    
    // 1.测试线程的销毁
    [self threadTest];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self performSelector:@selector(subThreadOpetion) onThread:self.subThread withObject:nil waitUntilDone:NO];
}

- (void)threadTest
{
    HLThread *subThread = [[HLThread alloc] initWithTarget:self selector:@selector(subThreadEntryPoint) object:nil];
    [subThread setName:@"HLThread"];
    [subThread start];
    self.subThread = subThread;
}

- (void)subThreadEntryPoint
{
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        //如果注释了下面这一行，子线程中的任务并不能正常执行
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        NSLog(@"启动RunLoop前--%@",runLoop.currentMode);
        NSLog(@"currentRunLoop:%@",[NSRunLoop currentRunLoop]);
        
        // 打印当前RunLoop中的Modes
        //    CFRunLoopRef runLoopRef = CFRunLoopGetCurrent();
        //    CFArrayRef modes = CFRunLoopCopyAllModes(runLoopRef);
        //    NSLog(@"打印当前RunLoop中的Modes:%@",modes);
        
        [runLoop run];
    }
}

/**
 子线程任务
 */
- (void)subThreadOpetion
{
    NSLog(@"启动RunLoop后--%@",[NSRunLoop currentRunLoop].currentMode);
    NSLog(@"%@----子线程任务开始",[NSThread currentThread]);
    [NSThread sleepForTimeInterval:3.0];
    NSLog(@"%@----子线程任务结束",[NSThread currentThread]);
}

@end
