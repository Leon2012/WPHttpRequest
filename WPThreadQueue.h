//
//  WPThreadQueue.h
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPThread;
@interface WPThreadQueue : NSObject{
    NSOperationQueue    *_queue;
    NSMutableArray      *_threads;   
    WPThread            *_lastThread;
}

@property(retain, nonatomic) WPThread   *lastThread;

+(WPThreadQueue *)singleThreadQueue;

//添加一个新的thread
-(void)addThread:(WPThread *)thread;
//添加一组新的thread
-(void)addThreads:(NSArray *)threads waitUntilFinished:(BOOL)wait;
//thread count , 包括了结束和没有结束的
-(NSInteger)threadCount;
//thread count, 只包括没有结束
-(NSInteger)activeThreadCount;
//thread是否已经结束
-(BOOL)isActived:(WPThread *)thread;
//thread是否存在
-(BOOL)isExist:(WPThread *)thread;
//根据index取出thread
-(WPThread *)threadAtIndex:(NSInteger)index;
//根据thre得到index
-(NSInteger)indexOfThread:(WPThread *)thread;
//替换一个thread
-(void)replaceThread:(WPThread *)thread atIndex:(NSUInteger)index;
//结束所有的thread
-(void)cancelAllThreads;
//结束所有的thread并且清除缓存
-(void)cancelAndClearThreads;
//结束某个thread
-(void)stopThread:(WPThread *)thread;
//结束某个thread根据index
-(void)stopThreadAtIndex:(NSInteger)index;
//cancel thread
-(void)cancelThread:(WPThread *)thread;
-(void)cancelThreadAtIndex:(NSInteger)index;

-(void)setMaxConcurrentOperationCount:(int)count;
-(NSArray *)allThreads;
@end
