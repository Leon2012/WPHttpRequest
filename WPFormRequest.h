//
//  WPFormRequest.h
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WPHttpRequest.h"

@interface WPFormRequest : WPHttpRequest{
    NSMutableData               *_postData;
    NSMutableData               *_fileData;
    NSStringEncoding            _stringEncoding;
    double                      _dataTotalLength;
    NSString                    *_boundary;
}
@property(assign)NSStringEncoding   stringEncoding;//default UTF8

+(WPFormRequest *)requestWithURLString:(NSString *)urlString;
-(void)addPostValue:(NSString *)value forKey:(NSString *)key;
-(void)addFile:(NSString *)filePath forKey:(NSString *)key;
-(void)addFileData:(NSData *)fileData fileName:(NSString *)fileName forKey:(NSString *)key;
-(void)startSynchronous;
-(void)startAsynchronous;

@end
