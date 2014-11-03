//
//  WPThreadQueue.m
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WPThreadQueue.h"
#import "WPThread.h"

@implementation WPThreadQueue
@synthesize lastThread = _lastThread;

-(void)dealloc{
    _R(_queue);
    _R(_threads);
    _R(_lastThread);
    [super dealloc];
}

+(WPThreadQueue *)singleThreadQueue{
    static WPThreadQueue *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WPThreadQueue alloc] init];
        [sharedInstance setMaxConcurrentOperationCount:1];
    });
    return sharedInstance;
}

-(id)init{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
        _threads = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark -
#pragma mark 相关方法
-(void)addThread:(WPThread *)thread{
    [thread retain];
    [_queue addOperation:thread];
    [_threads addObject:thread];
    _lastThread = thread; 
}

-(void)addThreads:(NSArray *)threads waitUntilFinished:(BOOL)wait{
    [_queue addOperations:threads waitUntilFinished:wait];
    [_threads addObjectsFromArray:threads];
    _lastThread = (WPThread *)[threads objectAtIndex:([threads count] - 1)];
    [_lastThread retain];
}

-(NSInteger)threadCount{
    return [_threads count];
}

-(NSInteger)activeThreadCount{
    return [_queue operationCount];
}

-(BOOL)isActived:(WPThread *)thread{
    NSArray *threads = [_queue operations];
    return [threads containsObject:thread];
}

-(WPThread *)threadAtIndex:(NSInteger)index{
    return [_threads objectAtIndex:index];
}

-(NSInteger)indexOfThread:(WPThread *)thread{
    return [_threads indexOfObject:thread];
}

-(void)replaceThread:(WPThread *)thread atIndex:(NSUInteger)index{
    WPThread *oldThread = [_threads objectAtIndex:index];
    if ([self isActived:oldThread]) {
        [oldThread finished];
    }
    [thread addPriority:1];
    [_queue addOperation:thread];
    [_threads replaceObjectAtIndex:index withObject:thread];
}

-(BOOL)isExist:(WPThread *)thread{
    if ([_threads containsObject:thread]) {
        ITLog(@"index -> %d", [self indexOfThread:thread]);
        return YES;
    }
    return NO;
}

-(void)cancelAllThreads{
    [_queue cancelAllOperations];
}

-(void)cancelAndClearThreads{
    [self cancelAndClearThreads];
    [_threads removeAllObjects];
}

-(void)stopThread:(WPThread *)thread{
    if ([thread isExecuting]) {
        [thread finished];
    }
}

-(void)stopThreadAtIndex:(NSInteger)index{
    WPThread *thread = [self threadAtIndex:index];
    if (thread) {
        [self stopThread:thread];
    }
}

-(void)cancelThread:(WPThread *)thread{
    if ([self isActived:thread]) {
        [thread canceled];
    }
}

-(void)cancelThreadAtIndex:(NSInteger)index{
    WPThread *thread = [self threadAtIndex:index];
    if (thread) {
        [self cancelThread:thread];
    }
}

-(void)setMaxConcurrentOperationCount:(int)count{
    [_queue setMaxConcurrentOperationCount:count];
}

-(NSArray *)allThreads{
    return _threads;
}

@end
