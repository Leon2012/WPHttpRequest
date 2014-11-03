//
//  WPThread.h
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPThreadDelegate.h"
#import "WPThreadStatus.h"

/*
 *Abstract Class
 */
@class WPException;
@interface WPThread : NSOperation{
    NSString                        *_name;//当前线程的name
    WPException                     *_exception;
    BOOL                            _executing;//是否正在执行
    BOOL                            _finished;//是否已经结束
    int                             _tag;//当前线程的tag 
    THREAD_STATUS                   _status;
    id<WPThreadDelegate>            _threadDelegate;
}

@property(readonly) NSString                  *name;
@property(readonly,getter=isWaitting ) BOOL   isWaitting;
@property(readonly,getter=isFailed)    BOOL   isFailed;
@property(readonly,getter=isSuspended) BOOL   isSuspended;
@property(assign)int                          tag;
@property(assign) id<WPThreadDelegate>        threadDelegate;
@property(retain, nonatomic) WPException      *exception;


-(id)initWithName:(NSString *)aName;

/*
 *Abstract Method
 *需要override此方法
 */
-(void)run;

-(THREAD_STATUS)status;
-(void)addPriority:(NSInteger)priority;
-(void)suspended;
-(void)canceled;
-(void)failed;
-(void)finished;
-(void)exit;




@end
