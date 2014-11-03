//
//  WPThread.m
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WPThread.h"
#import "WPThreadNotification.h"

@interface WPThread()
-(BOOL)isEqualToObject:(WPThread *)object;
-(void)forceExitThread;
@end

@implementation WPThread
@synthesize name = _name, tag = _tag, threadDelegate = _threadDelegate,exception = _exception;
@dynamic isWaitting, isFailed, isSuspended;

-(void)dealloc{
    _R(_name);
    _R(_exception);
    [super dealloc];
}

-(id)initWithName:(NSString *)aName{
    self = [super init];
    if (self) {
        [self willChangeValueForKey:@"name"];
        _name = [aName retain];
        [self didChangeValueForKey:@"name"];
        _tag = 0;
        _executing = NO;
        _finished  = NO;
        _exception = nil;
        [self setQueuePriority:NSOperationQueuePriorityNormal];//默认优先级是0
        [self willChangeValueForKey:@"status"];
        _status = THREAD_WAITTING;
        [self didChangeValueForKey:@"status"];
        [[NSNotificationCenter defaultCenter] postNotificationName:wpThreadWaittingNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self forKey:@"thread"]];
    }
    return self;
}

#pragma mark -
#pragma mark 线程允许多个线程一起运行
-(BOOL)isConcurrent{
    return YES;
}

#pragma mark -
#pragma mark 线程是否在运行
-(BOOL)isExecuting{
    return _executing;
}

#pragma mark -
#pragma mark 线程是否结束
-(BOOL)isFinished{
    return _finished;
}

#pragma mark -
#pragma mark 线程是否是等待状态
-(BOOL)isWaitting{
    if (_status == THREAD_WAITTING) {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark 线程出错
-(BOOL) isFailed{
    if (_status == THREAD_FAILED) {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark 线程挂起
-(BOOL) isSuspended{
    if (_status == THREAD_SUSPENDED) {
        return YES;
    }
    return NO;
}

#pragma mark -
#pragma mark 线程入口
-(void)start{
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        
        [self willChangeValueForKey:@"status"];
        _status = THREAD_CANCELED;
        [self didChangeValueForKey:@"status"];
        return;
    }
    if ([_threadDelegate respondsToSelector:@selector(threadStarted:)]) {
        [_threadDelegate threadStarted:self];
    }
    [self willChangeValueForKey:@"status"];
    _status = THREAD_EXECUTING;
    [self didChangeValueForKey:@"status"];
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    if ([self respondsToSelector:@selector(run)]) {
        [self performSelector:@selector(run)];
    }
    [self didChangeValueForKey:@"isExecuting"];
}

#pragma mark -
#pragma mark 线程执行方法
-(void)run{
    [[NSNotificationCenter defaultCenter] postNotificationName:wpThreadExecutingNotification 
                                                        object:nil 
                                                      userInfo:[NSDictionary dictionaryWithObject:self 
                                                                                           forKey:@"thread"]];
}

#pragma mark -
#pragma mark 结束线程的时候执行
-(void)canceled{
    if (!self.isCancelled) {
        [self cancel];
    }
    [self willChangeValueForKey:@"isFinished"];
    _finished = NO;//此处必需要返回NO,否则会报错
    [self didChangeValueForKey:@"isFinished"];
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"status"];
    _status = THREAD_CANCELED;
    [self didChangeValueForKey:@"status"];
    [[NSNotificationCenter defaultCenter] postNotificationName:wpThreadCanceledNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self forKey:@"thread"]];
    if ([_threadDelegate respondsToSelector:@selector(threadCanceled:)]) {
        [_threadDelegate threadCanceled:self];
    }
    [self forceExitThread];
}
#pragma mark -
#pragma mark 线程出错的时候执行
-(void)failed{
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"status"];
    _status = THREAD_FAILED;
    [self didChangeValueForKey:@"status"];
    [[NSNotificationCenter defaultCenter] postNotificationName:wpThreadFailedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self forKey:@"thread"]];
    if ([_threadDelegate respondsToSelector:@selector(threadFailed:)]) {
        [_threadDelegate threadFailed:self];
    }
}

#pragma mark -
#pragma mark 线程结束的时候执行
-(void)finished{
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"status"];
    _status = THREAD_FINISHED;
    [self didChangeValueForKey:@"status"];
    [[NSNotificationCenter defaultCenter] postNotificationName:wpThreadFinishedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self forKey:@"thread"]];
    if ([_threadDelegate respondsToSelector:@selector(threadFinished:)]) {
        [_threadDelegate threadFinished:self];
    }
}

#pragma mark -
#pragma mark 线程挂起的时候执行
-(void)suspended{
    if (!self.isCancelled) {
        [self cancel];
    }
    [self willChangeValueForKey:@"isFinished"];
    _finished = YES;
    [self didChangeValueForKey:@"isFinished"];
    
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"status"];
    _status = THREAD_SUSPENDED;
    [self didChangeValueForKey:@"status"];  
    [[NSNotificationCenter defaultCenter] postNotificationName:wpThreadSuspendedNotification object:nil userInfo:[NSDictionary dictionaryWithObject:self forKey:@"thread"]];
    if ([_threadDelegate respondsToSelector:@selector(threadSuspended:)]) {
        [_threadDelegate threadSuspended:self];
    }
}

#pragma mark -
#pragma mark 退出Thread
-(void)exit{
    [self canceled];
    [self performSelector:@selector(forceExitThread)];
}

-(void)forceExitThread{
    ITLog(@"current thread -> %@", [NSThread currentThread]);
    if (![[NSThread currentThread] isCancelled]) {
        [[NSThread currentThread] cancel];
    }
    if ([[NSThread currentThread] isCancelled]) {
        [NSThread exit];
    }
}

#pragma mark -
#pragma mark set priority
-(void)addPriority:(NSInteger)priority{
    [self willChangeValueForKey:@"queuePriority"];
    NSInteger _prority = [self queuePriority];
    [self setQueuePriority:(_prority+priority)];
    [self didChangeValueForKey:@"queuePriority"];
}


#pragma mark -
#pragma mark status code
-(THREAD_STATUS)status{
    return _status;
}

#pragma mark -
#pragma mark 重载父类方法
-(NSUInteger)hash{
    NSUInteger hash = 0;
    hash += [[self name] hash];
    hash += _tag;
    return hash;
}

-(BOOL)isEqual:(id)object{
    if (object == self) {
        return YES;
    }
    if (!object || ![object isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToObject:object];
}

-(BOOL)isEqualToObject:(WPThread *)object{
    if (![self.name isEqualToString:object.name]) {
        return NO;
    }
    if (self.tag != object.tag) {
        return NO;
    }
    return YES;
}

@end
