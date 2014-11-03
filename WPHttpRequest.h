//
//  WPHttpRequest.h
//  WPNetwork
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WPHttpRequestDelegate.h"
#import "WPHttpRequestProgressDelegate.h"
#import "WPThread.h"
#import "WPProxyInfo.h"

typedef enum _HTTP_REQUEST_METHOD{
    METHOD_GET,
    METHOD_POST,
    METHOD_HEAD,
    METHOD_PUT
}REQUEST_METHOD;

typedef enum _REQUEST_TYPE{
    HTTP_REQUEST,
    FORM_REQUEST
}REQUEST_TYPE;

@interface WPHttpRequest : WPThread{
    NSURL                               *_url;
    CFHTTPMessageRef                    _request;
    CFHTTPMessageRef                    _response;
    CFReadStreamRef                     _readStream;
    NSError                             *_error;
    NSTimeInterval                      _timeoutInterval;
    NSTimer                             *_timer;
    NSMutableDictionary                 *_requestHeaders;
    NSMutableData                       *_requestData;
    NSDictionary                        *_responseHeaders;
    NSMutableData                       *_responseData;
    id<WPHttpRequestDelegate>           _delegate;
    id<WPHttpRequestProgressDelegate>   _progressDelegate;
    NSInteger                           _statusCode;
    NSHTTPCookieStorage                 *_cookieStorage;
    BOOL                                _isHandleCookies;
    BOOL                                _isPersistentConnection;
    REQUEST_METHOD                      _requestMethod;
    CFRunLoopRef                        _runLoop;
    CFStringRef                         _runLoopMode;
    BOOL                                _isUseSystemProxy;
    BOOL                                _isSynchronous;
    UInt64                              _contentLength;//总共需接收的数据长度
    UInt64                              _receivedContentLength;//当前已经接收的数据长度
    BOOL                                _isOnlyResponseHeaders;//当前request只是为了取得response headers，主要用于在下载文件的时候取得文件的大小，默认为NO
    REQUEST_TYPE                        _requestType;
    WPProxyInfo                         *_proxyInfo;
    BOOL                                _isAutoSaveResponseData;
    
    //For Authentication
    NSString                            *_userName;
    NSString                            *_password;
    BOOL                                _isNeedAuth;
    CFHTTPAuthenticationRef             _requestAuthentication;
    NSDictionary                        *_requestCredentical;
    NSLock                              *_requestNeedAuthLock;
    NSString                            *_requestAuthenticationScheme;
}

@property(assign, nonatomic)id<WPHttpRequestDelegate>          delegate;
@property(assign, nonatomic)id<WPHttpRequestProgressDelegate>  progressDelegate;
@property(assign, nonatomic)NSTimeInterval                     timeoutInterval;
@property(assign, nonatomic)REQUEST_METHOD                     requestMethod;
@property(assign, nonatomic)BOOL                               isHandleCookies;
@property(assign, nonatomic)BOOL                               isPersistentConnection;
@property(assign, nonatomic)BOOL                               isUseSystemProxy;//是否使用系统默认的proxy
@property(assign, nonatomic)BOOL                               isOnlyResponseHeaders;
@property(retain, nonatomic)WPProxyInfo                        *proxyInfo;
@property(assign, nonatomic)BOOL                               isAutoSaveResponseData;//是否自动保存Response Data, Default is YES

+(WPHttpRequest *)requestWithURLString:(NSString *)urlString;
+(WPHttpRequest *)requestWithURLString:(NSString *)urlString withURLParams:(NSDictionary *)urlParams;
-(id)initWithURL:(NSURL *)url;

-(NSURL *)url;

-(void)addRequestHeader:(NSString *)key value:(NSString *)value;
-(void)setRequestCookies:(NSArray *)cookies;
-(void)addCookieName:(NSString *)name value:(NSString *)value;
-(void)appendPostData:(NSData *)data;

-(void)startSynchronous;
-(void)startAsynchronous;
-(void)cancelLoad;

-(UInt64)contentLength;
-(UInt64)receivedContentLength;
-(BOOL)isResponseDataCompressed;//是否传输的是gzip压缩数据
-(NSData *)responseData;
-(NSDictionary *)responseHeaders;
-(NSData *)requestData;
-(NSDictionary *)requestHeaders;

-(NSError *)error;
-(NSInteger)statusCode;

-(void)setUserName:(NSString *)userName;
-(NSString *)userName;
-(void)setPassword:(NSString *)password;
-(NSString *)password;
-(BOOL)isNeedAuth;
-(NSString *)requestAuthenticationScheme;

+(NSString *)mimeTypeForFileAtPath:(NSString *)filePath;
+(NSString *)mimeTypeForFileExtensionName:(NSString *)extName;

@end
