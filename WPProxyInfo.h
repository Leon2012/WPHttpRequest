//
//  WPProxyInfo.h
//  WPHelper
//
//  Created by Peng Leon on 12/11/28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _PROXY_TYPE{
    TYPE_HTTP_PROXY,
    TYPE_HTTPS_PROXY,
    TYPE_SOCKS_V4_PROXY,
    TYPE_SOCKS_V5_PROXY,
    TYPE_FTP_PROXY
}ProxyType;

//支持kCFStreamPropertyHTTPProxy, kCFStreamPropertyFTPProxy, kCFStreamPropertySOCKSProxy
//kCFStreamPropertyHTTPProxy 支持的参数 HTTPS:{kCFStreamPropertyHTTPSProxyHost, kCFStreamPropertyHTTPSProxyPort} HTTP:{kCFStreamPropertyHTTPProxyHost, kCFStreamPropertyHTTPProxyPort}
//kCFStreamPropertyFTPProxy  支持的参数 FTP:{kCFStreamPropertyFTPProxyHost, kCFStreamPropertyFTPProxyPort, kCFStreamPropertyFTPProxyUser, kCFStreamPropertyFTPProxyPassword}
//kCFStreamPropertySOCKSProxy 支持的参数 SOCK:{kCFStreamPropertySOCKSProxyHost, kCFStreamPropertySOCKSProxyPort, kCFStreamPropertySOCKSVersion, kCFStreamSocketSOCKSVersion4, kCFStreamSocketSOCKSVersion5, kCFStreamPropertySOCKSUser, kCFStreamPropertySOCKSPassword} 


@interface WPProxyInfo : NSObject{
    ProxyType       _proxyType;
    NSString        *_host;
    int             _port;
    NSString        *_user;
    NSString        *_password;
}
@property(assign, nonatomic) ProxyType  proxyType;
@property(retain, nonatomic) NSString   *host;
@property(retain, nonatomic) NSString   *user;
@property(retain, nonatomic) NSString   *password;
@property(assign, nonatomic) int        port;

-(id)initWithType:(ProxyType)proxyType host:(NSString *)host port:(int)port user:(NSString *)user password:(NSString *)password;

-(NSString *)type;
-(NSDictionary *)info;

@end

@interface WPProxyInfo(SystemHttpProxy)

#if TARGET_OS_IPHONE
+(WPProxyInfo *)systemHttpProxy; //iOS设备，只能手动设置HTTP代理，不能设置FTP/SOCKS代理
#endif

@end
