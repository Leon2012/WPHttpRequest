//
//  WPHttpRequestProgressDelegate.h
//  WPNetwork
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WPHttpRequest;
@protocol WPHttpRequestProgressDelegate <NSObject>
-(void)request:(WPHttpRequest *)request didSendBytes:(UInt64)bytes;//已经上传的字节长度
-(void)request:(WPHttpRequest *)request incrementUploadSizeBy:(UInt64)newLength;//总共需要上传的字节长度
-(void)request:(WPHttpRequest *)request didReceiveBytes:(UInt64)bytes;//已经接收到的字节长度
-(void)request:(WPHttpRequest *)request incrementDownloadSizeBy:(UInt64)newLength;//总共需要接收的字节长度
@end
