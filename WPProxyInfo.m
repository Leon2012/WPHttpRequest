//
//  WPProxyInfo.m
//  WPHelper
//
//  Created by Peng Leon on 12/11/28.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WPProxyInfo.h"
#include <CFNetwork/CFProxySupport.h>

@implementation WPProxyInfo
@synthesize port = _port, host = _host, user = _user, password = _password, proxyType = _proxyType;

-(void)dealloc{
    _R(_host);
    _R(_user);
    _R(_password);
    [super dealloc];
}

-(id)initWithType:(ProxyType)proxyType host:(NSString *)host port:(int)port user:(NSString *)user password:(NSString *)password{
    self = [super init];
    if (self) {
        _proxyType = proxyType;
        _host = [host retain];
        _port = port;
        if (_user != nil) {
            _user = [user retain];
        }
        if (_password != nil) {
            _password = [password retain];
        }
    }
    return self;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"proxyType:%d, host:%@, port:%d, user:%@, password:%@", _proxyType, _host, _port, _user, _password];
}

-(NSString *)type{
    CFStringRef type;
    switch (_proxyType) {
        case TYPE_HTTP_PROXY:
        case TYPE_HTTPS_PROXY:{    
            type = kCFStreamPropertyHTTPProxy;
        }break;
            
        case TYPE_SOCKS_V4_PROXY:
        case TYPE_SOCKS_V5_PROXY:{
            type = kCFStreamPropertySOCKSProxy;
        }break;
            
        case TYPE_FTP_PROXY:{
            type = kCFStreamPropertyFTPProxy;
        }break;    
    }
    return (NSString *)type;
}

-(NSDictionary *)info{
    NSDictionary *info = nil;
    switch (_proxyType) {
        case TYPE_HTTP_PROXY:{
            if (_host == nil) {
                info = nil;
            }else{
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertyHTTPProxyHost, 
                                 (NSString *)kCFStreamPropertyHTTPProxyPort, 
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    _host, 
                                    [NSNumber numberWithInt:_port], 
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }

        }break;
            
        case TYPE_HTTPS_PROXY:{    
            if (_host == nil) {
                info = nil;
            }else{
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertyHTTPSProxyHost, 
                                 (NSString *)kCFStreamPropertyHTTPSProxyPort, 
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    _host, 
                                    [NSNumber numberWithInt:_port], 
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }

        }break;
            
        case TYPE_SOCKS_V4_PROXY:{
            if (_host == nil) {
                return nil;
            }
            if (_user == nil || _password == nil) {
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertySOCKSVersion, 
                                 (NSString *)kCFStreamPropertySOCKSProxyHost,
                                 (NSString *)kCFStreamPropertySOCKSProxyPort,
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    (NSString *)kCFStreamSocketSOCKSVersion4,
                                    _host, 
                                    [NSNumber numberWithInt:_port],
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }else{
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertySOCKSVersion, 
                                 (NSString *)kCFStreamPropertyFTPProxyHost, 
                                 (NSString *)kCFStreamPropertyFTPProxyPort,
                                 (NSString *)kCFStreamPropertyFTPProxyUser,
                                 (NSString *)kCFStreamPropertyFTPProxyPassword,
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    (NSString *)kCFStreamSocketSOCKSVersion4,
                                    _host, 
                                    [NSNumber numberWithInt:_port],
                                    _user,
                                    _password,
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }

        }break;
            
        case TYPE_SOCKS_V5_PROXY:{
            if (_host == nil) {
                return nil;
            }
            if (_user == nil || _password == nil) {
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertySOCKSVersion, 
                                 (NSString *)kCFStreamPropertySOCKSProxyHost,
                                 (NSString *)kCFStreamPropertySOCKSProxyPort,
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    (NSString *)kCFStreamSocketSOCKSVersion5,
                                    _host, 
                                    [NSNumber numberWithInt:_port],
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }else{
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertySOCKSVersion, 
                                 (NSString *)kCFStreamPropertyFTPProxyHost, 
                                 (NSString *)kCFStreamPropertyFTPProxyPort,
                                 (NSString *)kCFStreamPropertyFTPProxyUser,
                                 (NSString *)kCFStreamPropertyFTPProxyPassword,
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    (NSString *)kCFStreamSocketSOCKSVersion5,
                                    _host, 
                                    [NSNumber numberWithInt:_port],
                                    _user,
                                    _password,
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }

        }break;
            
        case TYPE_FTP_PROXY:{
            if (_host == nil) {
                return nil;
            }
            if (_user == nil || _password == nil) {
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertyFTPProxyHost, 
                                 (NSString *)kCFStreamPropertyFTPProxyPort,
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    _host, 
                                    [NSNumber numberWithInt:_port],
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }else{
                NSArray *keys = [NSArray arrayWithObjects:
                                 (NSString *)kCFStreamPropertyFTPProxyHost, 
                                 (NSString *)kCFStreamPropertyFTPProxyPort,
                                 (NSString *)kCFStreamPropertyFTPProxyUser,
                                 (NSString *)kCFStreamPropertyFTPProxyPassword,
                                 nil];
                NSArray *objects = [NSArray arrayWithObjects:
                                    _host, 
                                    [NSNumber numberWithInt:_port],
                                    _user,
                                    _password,
                                    nil];
                info = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
            }
            

        }break;    
    }
    
    
    return info;
}

@end


@implementation WPProxyInfo(SystemHttpProxy)

+(WPProxyInfo *)systemHttpProxy{
    NSDictionary *proxySettings = [NSMakeCollectable(CFNetworkCopySystemProxySettings()) autorelease];
    BOOL isEnable = [[proxySettings objectForKey:(NSString*)kCFNetworkProxiesHTTPEnable] boolValue];
    if (isEnable) {
        NSString *host = [proxySettings objectForKey:(NSString *)kCFNetworkProxiesHTTPProxy];
        int port = [[proxySettings objectForKey:(NSString *)kCFNetworkProxiesHTTPPort] intValue];
        NSString *user = [proxySettings objectForKey:@"HTTPUser"];
        NSString *password = [proxySettings objectForKey:@"HTTPPassword"];
        if (host) {
            WPProxyInfo *proxyInfo = [[WPProxyInfo alloc] initWithType:TYPE_HTTP_PROXY host:host port:port user:user password:password];
            return [proxyInfo autorelease];
        }
        
    }
    return nil;
}

@end
























