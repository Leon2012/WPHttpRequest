//
//  WPThreadDelegate.h
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WPThread;
@protocol WPThreadDelegate <NSObject>
@optional
//线程开始的时候调用的代理方法
-(void)threadStarted:(WPThread *)thread;
//线程结束的时候调用的代理方法
-(void)threadFinished:(WPThread *)thread;
//线程挂起的时候调用的代理方法
-(void)threadSuspended:(WPThread *)thread;
//线程取消的时候调用的代理方法
-(void)threadCanceled:(WPThread *)thread;
//线程出错的时候调用的代理方法
-(void)threadFailed:(WPThread *)thread;


@end