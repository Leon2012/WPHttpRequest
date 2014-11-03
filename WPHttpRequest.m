//
//  WPHttpRequest.m
//  WPNetwork
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WPHttpRequest.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WPNetworkQueue.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import <CFNetwork/CFNetwork.h>
#import "NSString+Util.h"
#import "NSData+Util.h"


@interface WPHttpRequest()
@property(retain, nonatomic) NSTimer *timer;

-(BOOL)doRequest;
-(void)setHeaderName:(NSString *)name value:(NSString *)value;
-(void)setProxyServiceToRequest;
-(void)setPostBodyToRequest;
-(void)setSSLProperties;
-(void)setRequestHeadersToRequest;
-(void)setRequestCookiesToRequest;
-(void)handleStreamEvent:(CFStreamEventType)type forStream:(CFTypeRef)stream;
-(NSError *)createErrorWithError:(CFStreamError)error;
-(NSError *)createNetworkErrorWithCode:(int)errorCode userInfo:(NSDictionary *)userInfo;
-(void)close;
-(void)read;
-(void)applyAuthorizationHeader;
-(void)addBasicAuthenticationHeaderWithUsername:(NSString *)theUsername andPassword:(NSString *)thePassword;

@end

static void myReadCallBack (CFReadStreamRef stream, CFStreamEventType event, void *myPtr);;
void myReadCallBack (CFReadStreamRef stream, CFStreamEventType event, void *myPtr) {
    NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
    WPHttpRequest *asyncRequest = [[(WPHttpRequest *)myPtr retain] autorelease];
    [asyncRequest handleStreamEvent:event forStream:stream];
    [aPool drain];
}

@implementation WPHttpRequest
@synthesize delegate = _delegate, timeoutInterval = _timeoutInterval, requestMethod = _requestMethod;
@synthesize isHandleCookies = _isHandleCookies, progressDelegate = _progressDelegate;
@synthesize isPersistentConnection = _isPersistentConnection, proxyInfo = _proxyInfo;
@synthesize isUseSystemProxy = _isUseSystemProxy, isOnlyResponseHeaders = _isOnlyResponseHeaders;
@synthesize timer = _timer, isAutoSaveResponseData = _isAutoSaveResponseData;

-(void)dealloc{
    _R(_url);
    _timeoutInterval = 0;
    _R(_timer);
    _R(_requestHeaders);
    _R(_responseHeaders);
    _delegate = nil;
    _progressDelegate = nil;
    _requestMethod = 0;
    _R(_responseData);
    _R(_requestData);
    _R(_proxyInfo);
    CFRelease(_request);
    _request = NULL;
    CFRelease(_response);
    _response = NULL;
    _R(_userName);
    _R(_password);
    if (_requestAuthentication) {
        CFRelease(_requestAuthentication);
    }
    _R(_requestCredentical);
    _R(_requestNeedAuthLock);
    [self close];
    [super dealloc];
}

+(WPHttpRequest *)requestWithURLString:(NSString *)urlString{
    return [WPHttpRequest requestWithURLString:urlString withURLParams:nil];
}

+(WPHttpRequest *)requestWithURLString:(NSString *)urlString withURLParams:(NSDictionary *)urlParams{
    NSURL *url = nil;
    if (urlParams != nil) {
        NSMutableString *urlParamsString = [NSMutableString string];
        NSArray *allKeys = [urlParams allKeys];
        for (NSString *key in allKeys) {
            NSString *value = [urlParams objectForKey:key];
            [urlParamsString appendFormat:@"&%@=%@", key, value];
        }
        url = [NSURL URLWithString:[urlString stringByAppendingString:urlParamsString]];
    }else{
        url = [NSURL URLWithString:urlString]; 
    }
    if (url != nil) {
        WPHttpRequest *request = [[WPHttpRequest alloc] initWithURL:url];
        return [request autorelease];
    }
    return nil;
}

-(id)initWithURL:(NSURL *)url{
    self = [super initWithName:[url absoluteString]];
    if (self) {
        _url = [url retain];
        _requestMethod = METHOD_GET;
        _timeoutInterval = 30;
        _isHandleCookies = NO;
        _isPersistentConnection = NO;
        _isUseSystemProxy = NO;
        _isSynchronous = NO;
        _isAutoSaveResponseData = YES;
        _requestHeaders = [[NSMutableDictionary alloc] init];
        _responseData = [[NSMutableData alloc] init];
        _cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        _requestData = [[NSMutableData alloc] init];
        _isOnlyResponseHeaders = NO;
        _requestType = HTTP_REQUEST;
        _requestNeedAuthLock = [[NSLock alloc] init];
        _isNeedAuth = NO;
    }
    return self;
}

-(void)applyAuthorizationHeader{
    
    if (![[self responseHeaders] objectForKey:@"Authorization"]) {
        if (([self userName] != nil) && ([self password] != nil)) {
            [self addBasicAuthenticationHeaderWithUsername:_userName andPassword:_password];
        }
    }
}

-(void)addBasicAuthenticationHeaderWithUsername:(NSString *)theUsername andPassword:(NSString *)thePassword{
    NSString *key = @"Authorization";
    NSString *userNameAndPassword = [NSString stringWithFormat:@"%@:%@", theUsername, thePassword];
    NSData *userNameAndPasswordData = [userNameAndPassword dataUsingEncoding:NSUTF8StringEncoding];
    NSString *userNameAndPasswordHash = [userNameAndPasswordData base64Encoding];
    NSString *value = [NSString stringWithFormat:@" Basic %@", userNameAndPasswordHash];
    [self addRequestHeader:key value:value];
    _requestAuthenticationScheme = (NSString *)kCFHTTPAuthenticationSchemeBasic;
}

-(void)setProxyServiceToRequest{
    //读取系统设置
    /*
     if (_isUseSystemProxy) {
     CFDictionaryRef proxyDict = CFNetworkCopySystemProxySettings(); 
     NSArray *proxies = [NSMakeCollectable(CFNetworkCopyProxiesForURL((CFURLRef)_url, (CFDictionaryRef)proxyDict)) autorelease];
     if ([proxies count] > 0) {
     NSDictionary *settings = [proxies objectAtIndex:0];
     _proxyType = [settings objectForKey:(NSString *)kCFProxyTypeKey];
     NSString *proxyHost = [settings objectForKey:(NSString *)kCFProxyHostNameKey];
     int proxyPortNumber = [[settings objectForKey:(NSString *)kCFProxyPortNumberKey] intValue];
     
     }
     }
     */
    if (_isUseSystemProxy) {
        _proxyInfo = [WPProxyInfo systemHttpProxy];
    }    
    if (_proxyInfo != nil) {
        CFStringRef type = (CFStringRef)[_proxyInfo type];
        NSDictionary *info = [_proxyInfo info];
        ITLog(@"proxy info -> %@", _proxyInfo);
        if (info != nil) {
            CFReadStreamSetProperty(_readStream, type, (CFDictionaryRef)info);
        }
    }
}

-(void)setPostBodyToRequest{
    if (_requestType == HTTP_REQUEST){
        if (_requestMethod == METHOD_POST) {
            NSData *postData = [NSData dataWithData:_requestData];
            NSString *postString = [[[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding] autorelease];
            ITLog(@"request string -> %@", postString);
            CFHTTPMessageSetBody(_request, (CFDataRef)postData);
            NSString *contentType = [_requestHeaders objectForKey:@"Content-Type"];
            if (contentType == nil) {
                [self setHeaderName:@"Content-Type" value:@"application/x-www-form-urlencoded"];//post数据的时候，一定需要设置此header，要不然就无法得到post的数据
            }
            NSString *contentLength = [_requestHeaders objectForKey:@"Content-Length"];
            if (contentLength == nil) {
                [self setHeaderName:@"Content-Length" value:[NSString stringWithFormat:@"%d",[postData length]]];
            }
        }else{
            CFHTTPMessageSetBody(_request, (CFDataRef)_requestData);
        }
    }else{
        NSData *postData = [NSData dataWithData:_requestData];
        CFHTTPMessageSetBody(_request, (CFDataRef)postData);
        NSString *contentLength = [_requestHeaders objectForKey:@"Content-Length"];
        if (contentLength == nil) {
            [self setHeaderName:@"Content-Length" value:[NSString stringWithFormat:@"%d",[postData length]]];
        }
    }
}

-(void)setSSLProperties{
    //see: http://iphonedevelopment.blogspot.com/2010/05/nsstream-tcp-and-ssl.html
    NSDictionary *sslProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredCertificates,
                                   [NSNumber numberWithBool:YES], kCFStreamSSLAllowsAnyRoot,
                                   (id)kCFBooleanFalse, (NSString *)kCFStreamSSLValidatesCertificateChain,//不验证Https
                                   @"kCFStreamSocketSecurityLevelTLSv1_0SSLv3", (NSString *)kCFStreamSSLLevel,//For TLS1.2 support in iOS 5
                                   kCFNull,kCFStreamSSLPeerName,
                                   nil];
    CFReadStreamSetProperty(_readStream, kCFStreamPropertySocketSecurityLevel, kCFStreamSocketSecurityLevelNegotiatedSSL);
    CFReadStreamSetProperty(_readStream, kCFStreamPropertySSLSettings, sslProperties);
}

-(void)setHeaderName:(NSString *)name value:(NSString *)value{
    CFStringRef headerFieldName =  (CFStringRef)name;
    CFStringRef headerFieldValue = (CFStringRef)value;
    CFHTTPMessageSetHeaderFieldValue(_request, headerFieldName, headerFieldValue);
}

-(void)setRequestHeadersToRequest{
    //[_requestHeaders setObject:@"gzip" forKey:@"Accept-Encoding"];
    NSArray *keys = [_requestHeaders allKeys];
    for (int i=0; i<[keys count]; i++) {
        NSString *key = [keys objectAtIndex:i];
        NSString *value = [_requestHeaders objectForKey:key];
        [self setHeaderName:key value:value];
    }
}

-(void)setRequestCookiesToRequest{
    if (_isHandleCookies) {
        NSArray *cookies = [_cookieStorage cookiesForURL:_url];
        if ([cookies count] > 0) {
            NSDictionary *cookieInfo = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
            if (cookieInfo) {
                [self setHeaderName:@"Cookie" value:(NSString *)[cookieInfo objectForKey:@"Cookie"]];
            }
        }
    }
}

-(BOOL)doRequest{
    _contentLength = 0;
    _receivedContentLength = 0;
    BOOL isOK = NO;
    if (_url == nil) {
        return isOK;
    }
    NSString *method = @"GET";
    switch (_requestMethod) {
        case METHOD_GET:{
            method = @"GET";
        }break;
        case METHOD_POST:{
            method = @"POST";
        }break;    
        case METHOD_HEAD:{
            method = @"HEAD";
        }break;   
        case METHOD_PUT:{
            method = @"PUT";
        }break;               
    }
    _request =  CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)method, (CFURLRef)_url, kCFHTTPVersion1_1);//创建request;
    if (_request == NULL) {
        return isOK;
    }

    [self applyAuthorizationHeader];
    [self setRequestHeadersToRequest];
    [self setRequestCookiesToRequest];
    [self setPostBodyToRequest];

    NSDictionary *requestHeaders = (NSDictionary *)CFHTTPMessageCopyAllHeaderFields(_request);
    ITLog(@"request headers -> %@", requestHeaders);
    CFRelease(requestHeaders);
    
    _readStream = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, _request);
    CFStreamClientContext context = {0, self, NULL, NULL, NULL};
    CFOptionFlags registeredEvents = kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered | kCFStreamEventOpenCompleted;
    isOK = CFReadStreamSetClient(_readStream, registeredEvents, myReadCallBack, &context);
    if (!isOK) {
        return NO;
    }
    //设备代理服务器
    [self setProxyServiceToRequest];
    
    //设置是否瞬时连接
    if (_isPersistentConnection) {
        CFReadStreamSetProperty(_readStream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue);
    }else{
        CFReadStreamSetProperty(_readStream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanFalse);
    }
    //设置成自动跳转，如遇到跳转的页面，会自动去读取新的页面
    CFReadStreamSetProperty(_readStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);
    //设置ssl
    if ([[[_url scheme] lowercaseString] isEqualToString:@"https"]) {//此处ssl设置成不验证https，否则则需要本地证书支持
        [self setSSLProperties];
    }
    
    //添加到RunLoop
    _runLoop = CFRunLoopGetCurrent();
    _runLoopMode = kCFRunLoopDefaultMode;
    CFReadStreamScheduleWithRunLoop(_readStream, _runLoop, _runLoopMode);
    
    //设置连接超时
    self.timer = [NSTimer timerWithTimeInterval:_timeoutInterval 
                                             target:self 
                                           selector:@selector(doReadTimeout:) 
                                           userInfo:nil 
                                            repeats:NO];//用来判断是否超时, 如果正常发送完成系统会正动block掉这一个NSTimer，否则这个doWriteTimeout，则会被调用
    CFRunLoopAddTimer(_runLoop, (CFRunLoopTimerRef)self.timer, (CFStringRef)_runLoopMode);
    
    //Open Read Stream
    isOK = CFReadStreamOpen(_readStream);
    if (!isOK) {
        CFStreamError streamError = CFReadStreamGetError(_readStream);
        _error = [self createErrorWithError:streamError];
        return NO;
    }
    isOK = YES;
    return isOK;
}

#pragma mark -
#pragma mark timeout Methods

-(void)doReadTimeout:(id)sender{
    [self performSelector:@selector(removeTimerFromRunLoop)];
    if ([_delegate respondsToSelector:@selector(requestFailed:error:)]  && (_isSynchronous == NO)) {
        [_delegate requestFailed:self error:[self createNetworkErrorWithCode:kCFURLErrorTimedOut userInfo:nil]];
    }
    [self canceled];
    //ITLog(@"time out....");
}

-(void)removeTimerFromRunLoop{
    if (self.timer != nil) {
        CFRunLoopRemoveTimer(_runLoop, (CFRunLoopTimerRef)self.timer, _runLoopMode);
        if (self.timer != nil) {
            [self.timer invalidate];
            self.timer = nil;
        }
    }
}

-(void)appendPostData:(NSData *)data{
    if (data) {
        [_requestData appendData:data];
    }
}

-(void)addRequestHeader:(NSString *)header value:(NSString *)value{
    NSString *newValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [_requestHeaders setObject:newValue forKey:header];
}

-(void)addCookieName:(NSString *)name value:(NSString *)value{
    NSString *newValue = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *domain = [_url host];
    NSDictionary *properties = [[[NSMutableDictionary alloc] init] autorelease];
    [properties setValue:newValue forKey:NSHTTPCookieValue];
    [properties setValue:name forKey:NSHTTPCookieName];
    [properties setValue:domain forKey:NSHTTPCookieDomain];
    [properties setValue:[NSDate dateWithTimeIntervalSinceNow:60*60] forKey:NSHTTPCookieExpires];
    [properties setValue:@"/" forKey:NSHTTPCookiePath];
    NSHTTPCookie *aCookie = [[[NSHTTPCookie alloc] initWithProperties:properties] autorelease];
    if (aCookie) {
        [self setRequestCookies:[NSArray arrayWithObject:aCookie]];
    }
}

-(void)setRequestCookies:(NSArray *)cookies{
    if (cookies) {
        [_cookieStorage setCookies:cookies forURL:_url mainDocumentURL:nil];
    }
}

-(NSURL *)url
{
    return _url;
}

-(NSError *)error{
    return _error;
}

-(NSInteger)statusCode{
    return _statusCode;
}

-(void)startSynchronous{
    _isSynchronous = YES;
    BOOL isOK = [self doRequest];
    NSAssert(isOK, @"create request error...");
    if (isOK) {
        while (![self isCancelled] && ![self isFinished] && ![self isFailed]) {
            [[NSRunLoop currentRunLoop] runMode:(NSString *)_runLoopMode beforeDate:[NSDate distantFuture]];
        }
        //ITLog(@"All Request Finished.............................");
    }
}

-(void)startAsynchronous{
    _isSynchronous = NO;
    BOOL isOK = [self doRequest];
    NSAssert(isOK, @"create request error...");
    if (isOK) {
        [[WPNetworkQueue singleHttpRequestQueue] addThread:self];
    }
}

-(UInt64)contentLength{
    return _contentLength;
}

-(UInt64)receivedContentLength{
    return _receivedContentLength;
}

-(BOOL)isResponseDataCompressed{
    if (_responseHeaders == nil) {
        return NO;
    }
    NSString *encoding = [_responseHeaders objectForKey:@"Content-Encoding"];
    if (encoding == nil) {
        return NO;
    }
    NSRange range = [encoding rangeOfString:@"gzip"];
    if (range.location != NSNotFound) {
        return YES;
    }
    return NO;
}

-(NSData *)responseData{
    return [NSData dataWithData:_responseData];
}

-(NSDictionary *)responseHeaders{
    if (_responseHeaders == nil) {
        return nil;
    }
    return [NSDictionary dictionaryWithDictionary:_responseHeaders];
}

-(NSData *)requestData{
    return [NSData dataWithData:_requestData];
}

-(NSDictionary *)requestHeaders{
    if (_requestHeaders == nil) {
        return nil;
    }
    return [NSDictionary dictionaryWithDictionary:_requestHeaders];
}

-(void)setUserName:(NSString *)userName{
    if (![_userName isEqualToString:userName]) {
        [_userName release];
        [userName retain];
        _userName = userName;
    }
}

-(NSString *)userName{
    return _name;
}

-(void)setPassword:(NSString *)password{
    if (![_password isEqualToString:password]) {
        [_password release];
        [password retain];
        _password = password;
    }
}

-(NSString *)password{
    return _password;
}

-(BOOL)isNeedAuth{
    return _isNeedAuth;
}

-(NSString *)requestAuthenticationScheme{
    return _requestAuthenticationScheme;
}

-(void)cancelLoad{
    [self close];
    [self canceled];
}

#pragma mark -
#pragma mark 重载方法
-(void)run{
    @try {
        NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
        [super run];
        while (![self isCancelled] && ![self isFinished]) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        if ([self isCancelled] || [self isFailed]) {
            [self close];
        }
        //ITLog(@"All Request Finished.............................");
        [aPool drain];
    }
    @catch (NSException *aException) {
        [self close];
        [super failed];
    }
}

#pragma mark -
#pragma mark Read Stream
-(void)read{
    if (_readStream == NULL) {
        return;
    }
    UInt64 bufferSize = 16384;
    if (_contentLength > 262144) {
		bufferSize = 262144;
	} else if (_contentLength > 65536) {
		bufferSize = 65536;
	}
    BOOL done = NO;
    BOOL error = NO;
    while (!done && !error && ![self isCancelled]) {
        if (CFReadStreamHasBytesAvailable(_readStream)) {
            UInt8 buf[bufferSize];
            CFIndex bytesRead = CFReadStreamRead(_readStream, buf, bufferSize);
            if (bytesRead < 0) {
                error = YES;
            }else if(bytesRead == 0){
                done = YES;
            }else{
                NSData *data = [NSData dataWithBytes:buf length:bytesRead];
                _receivedContentLength += bytesRead;
                if ([_progressDelegate respondsToSelector:@selector(request:didReceiveBytes:)]) {
                    [_progressDelegate request:self didReceiveBytes:_receivedContentLength];
                }
                if (_isAutoSaveResponseData) {
                    [_responseData appendData:data];
                }
                if ([_delegate respondsToSelector:@selector(request:didReceiveData:)]  && (_isSynchronous == NO)) {
                    [_delegate request:self didReceiveData:data];
                }
            }
        }else{
            done = YES;
        }
    }
    if(error){
        CFStreamError streamError = CFReadStreamGetError(_readStream);
        if ([_delegate respondsToSelector:@selector(requestFailed:error:)]  && (_isSynchronous == NO)) {
            _error = [self createErrorWithError:streamError];
            [_delegate requestFailed:self error:_error];
        }
        return;
    }
}

#pragma mark -
#pragma mark stream event
-(void)handleStreamEvent:(CFStreamEventType)type forStream:(CFTypeRef)stream{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    switch (type) {
        case kCFStreamEventNone:{
        
        }break;
            
        case kCFStreamEventCanAcceptBytes:{
        
        }break;
            
        case kCFStreamEventHasBytesAvailable:{//stream read data event
            //ITLog(@"read dataing...");
             _response = (CFHTTPMessageRef)CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPResponseHeader);
            
            if (_response) {
                _statusCode = CFHTTPMessageGetResponseStatusCode(_response);
                if (_statusCode == 401 || _statusCode == 407) {
                    _isNeedAuth = YES;
                }
                
                CFDictionaryRef aResponseHeaders = CFHTTPMessageCopyAllHeaderFields(_response);
                if (_responseHeaders) {
                    [_responseHeaders release];
                    _responseHeaders = nil;
                }
                _responseHeaders = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)aResponseHeaders];
                CFRelease(aResponseHeaders);
                //ITLog(@"response headers -> %@", _responseHeaders);
                
                if ([_delegate respondsToSelector:@selector(request:didReceiveResponseHeaders:)]  && (_isSynchronous == NO)) {
                    [_delegate request:self didReceiveResponseHeaders:_responseHeaders];
                }
                
                //Handle Response Cookies
                if (_isHandleCookies) {
                    NSArray *newCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[self responseHeaders] forURL:[self url]];
                    if (newCookies) {
                        [self setRequestCookies:newCookies];
                    }
                }
                
                _contentLength = [[_responseHeaders objectForKey:@"Content-Length"] longLongValue];
                if ([_progressDelegate respondsToSelector:@selector(request:incrementDownloadSizeBy:)]) {
                    [_progressDelegate request:self incrementDownloadSizeBy:_contentLength];
                }
                
                if ([self isNeedAuth]) {
                    if (_requestAuthentication == NULL) {
                        CFHTTPMessageRef responseHeader = (CFHTTPMessageRef)CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPResponseHeader);
                        _requestAuthentication = CFHTTPAuthenticationCreateFromResponse(kCFAllocatorDefault, responseHeader);
                        CFRelease(responseHeader);
                        if (_requestAuthentication != NULL) {
                            _requestAuthenticationScheme = (NSString *)CFHTTPAuthenticationCopyMethod(_requestAuthentication);
                        }
                    }
                    [self close];
                    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(requestNeedAuthentication:)]) {
                        [self.delegate requestNeedAuthentication:self];
                    }
                }

                
            }else{
                [self canceled];
            }

            if (_isOnlyResponseHeaders) {
                [self canceled];
            }else{
                [self read];
            }
            
        }break;  
            
        case kCFStreamEventErrorOccurred:{//read stream error event
            //ITLog(@"read stream error occurred...");
            CFStreamError streamError = CFReadStreamGetError(_readStream); 
            if ([_delegate respondsToSelector:@selector(requestFailed:error:)]  && (_isSynchronous == NO)) {
                _error = [self createErrorWithError:streamError];
                [_delegate requestFailed:self error:_error];
            }
            [self canceled];
        }break;    
            
        case kCFStreamEventEndEncountered:{//read stream over event
            //ITLog(@"read stream end encountered...");
            [self close];
            if ([_delegate respondsToSelector:@selector(requestFinished:)] && (_isSynchronous == NO)) {
                [_delegate requestFinished:self];
            }
            [self finished];
        }break;
            
        case kCFStreamEventOpenCompleted:{//open read stream event
            //ITLog(@"read stream opened...");
            [_responseData setLength:0];
            [self performSelector:@selector(removeTimerFromRunLoop)];
            if ([_delegate respondsToSelector:@selector(requestStarted:)] && (_isSynchronous == NO)) {
                [_delegate requestStarted:self];
            }
        }break;            
    }
    

    [pool drain];
}

-(NSError *)createErrorWithError:(CFStreamError)streamError{
    NSDictionary *userInfo;
    if (streamError.domain == kCFStreamErrorDomainNetDB) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:streamError.error], kCFGetAddrInfoFailureKey,nil];
    }else{
        userInfo = nil;
    }
    return [self createNetworkErrorWithCode:kCFHostErrorUnknown userInfo:userInfo];
}

-(NSError *)createNetworkErrorWithCode:(int)errorCode userInfo:(NSDictionary *)userInfo{
    NSError *error;
    error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:errorCode userInfo:userInfo];
    return error;
}


-(void)close{
    //CFRunLoopStop(_runLoop);
    if (_readStream != NULL) {
        CFReadStreamClose(_readStream);
        CFReadStreamUnscheduleFromRunLoop(_readStream, _runLoop, _runLoopMode);
        CFRelease(_readStream);
        _readStream = NULL;
    }
}

#pragma mark -
#pragma mark 静态方法
+(NSString *)mimeTypeForFileAtPath:(NSString *)filePath{
    if (![[[[NSFileManager alloc] init] autorelease] fileExistsAtPath:filePath]) {
		return nil;
	}
    return [WPHttpRequest mimeTypeForFileExtensionName:[filePath pathExtension]];
}

+(NSString *)mimeTypeForFileExtensionName:(NSString *)extName{
    // Borrowed from http://stackoverflow.com/questions/2439020/wheres-the-iphone-mime-type-database
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extName, NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
	if (!MIMEType) {
		return @"application/octet-stream";
	}
    return [NSMakeCollectable(MIMEType) autorelease];
}



@end
