//
//  WPHttpRequestDelegate.h
//  WPNetwork
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WPHttpRequest;

@protocol WPHttpRequestDelegate <NSObject>
-(void)requestStarted:(WPHttpRequest *)request;//开始发送request
-(void)request:(WPHttpRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders;//接收到的response header
-(void)request:(WPHttpRequest *)request didReceiveData:(NSData *)data;//接收到的数据
-(void)requestFailed:(WPHttpRequest *)request error:(NSError *)error;//接收数据出错
-(void)requestFinished:(WPHttpRequest *)request;//接收数据完成

-(void)requestNeedAuthentication:(WPHttpRequest *)request;//需要身份验证

@end
