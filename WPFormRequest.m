//
//  WPFormRequest.m
//  WPHelper
//
//  Created by Peng Leon on 12/7/17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WPFormRequest.h"

#define DEFAULT_END_STRING @"\r\n"


@interface WPFormRequest()
-(void)doPostData;
-(NSString *)createBoundary;
-(void)buildPostData:(NSString *)value key:(NSString *)key;
-(void)buildFileData:(NSData *)data key:(NSString *)key fileName:(NSString *)name contentType:(NSString *)contentType;
-(NSData *)getDataFromFile:(NSString *)filePath;
@end


@implementation WPFormRequest
@synthesize stringEncoding = _stringEncoding;

-(void)dealloc{
    _R(_postData);
    _R(_fileData);
    _stringEncoding = 0;
    _dataTotalLength = 0;
    _R(_boundary);
    [super dealloc];
}

+(WPFormRequest *)requestWithURLString:(NSString *)urlString{
    return [[[WPFormRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
}

-(id)initWithURL:(NSURL *)url{
    self = [super initWithURL:url];
    if (self) {
        _requestMethod = METHOD_POST;
        _stringEncoding = NSUTF8StringEncoding;
        _dataTotalLength = 0;
        _boundary = [self createBoundary];
        _requestType = FORM_REQUEST;
    }
    return self;
}

-(void)addPostValue:(NSString *)value forKey:(NSString *)key{
    if (!key) return;
    [self buildPostData:value key:key];
}

-(void)buildPostData:(NSString *)value key:(NSString *)key{
    if (_postData == nil) {
        _postData = [[NSMutableData alloc] init];
    }
    NSMutableString *bufferString = [NSMutableString string];
    [bufferString appendString:DEFAULT_END_STRING];
    [bufferString appendString:[NSString stringWithFormat:@"--%@", _boundary]];
    [bufferString appendString:DEFAULT_END_STRING];
    NSString *nameString = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"", key];
    [bufferString appendString:nameString];
    [bufferString appendString:DEFAULT_END_STRING];
    [bufferString appendString:DEFAULT_END_STRING];
    [bufferString appendString:value];
    
    ITLog(@"post string -> %@", bufferString);
    
    NSData *aPair = [bufferString dataUsingEncoding:_stringEncoding];
    [_postData appendData:aPair];
}

-(void)addFile:(NSString *)filePath forKey:(NSString *)key{
    BOOL isDirectory = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!isExist || isDirectory) return;
    
    NSData *data = [self getDataFromFile:filePath];
    NSString *fileName = [filePath lastPathComponent];
    NSString *contentType = [WPHttpRequest mimeTypeForFileAtPath:filePath];
    if (contentType == nil) {
        contentType = @"application/octet-stream";
    }
    [self buildFileData:data key:key fileName:fileName contentType:contentType];
}

-(void)addFileData:(NSData *)fileData fileName:(NSString *)fileName forKey:(NSString *)key{
    NSString *contentType = [WPHttpRequest mimeTypeForFileExtensionName:[fileName pathExtension]];
    if (contentType == nil) {
        contentType = @"application/octet-stream";
    }
    [self buildFileData:fileData key:key fileName:fileName contentType:contentType];
}


-(NSData *)getDataFromFile:(NSString *)filePath{
    NSMutableData *fileData = [NSMutableData data];
    NSInputStream *stream = [[[NSInputStream alloc] initWithFileAtPath:filePath] autorelease];
	[stream open];
	NSUInteger bytesRead;
	while ([stream hasBytesAvailable]) {
		unsigned char buffer[1024*256];
		bytesRead = [stream read:buffer maxLength:sizeof(buffer)];
		if (bytesRead == 0) {
			break;
		}
        [fileData appendData:[NSData dataWithBytes:buffer length:bytesRead]];
	}
	[stream close];
    return [NSData dataWithData:fileData];
}

-(void)buildFileData:(NSData *)data key:(NSString *)key fileName:(NSString *)name contentType:(NSString *)contentType{
    if (_fileData == nil) {
        _fileData = [[NSMutableData alloc] init];
    }
    NSMutableString *bufferString = [NSMutableString string];
    NSMutableData   *bufferData = [NSMutableData data];
    [bufferString appendString:DEFAULT_END_STRING];
    [bufferString appendString:[NSString stringWithFormat:@"--%@", _boundary]];
    [bufferString appendString:DEFAULT_END_STRING];
    NSString *nameString = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"", key, name];
    [bufferString appendString:nameString];
    [bufferString appendString:DEFAULT_END_STRING];
    [bufferString appendString:[NSString stringWithFormat:@"Content-Type: %@", contentType]];
    [bufferString appendString:DEFAULT_END_STRING];
    [bufferString appendString:DEFAULT_END_STRING];
    
    ITLog(@"content string -> %@", bufferString);
    
    [bufferData appendData:[bufferString dataUsingEncoding:_stringEncoding]];
    [bufferData appendData:data];
    [_fileData appendData:bufferData];
}

-(void)doPostData{
    if (_stringEncoding == 0) {
        _stringEncoding = NSUTF8StringEncoding;
    }
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(_stringEncoding));
    [self addRequestHeader:@"Content-Type" value:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@",  charset, _boundary]];
    if (_fileData != nil) {
        [super appendPostData:_fileData];
    }
    [super appendPostData:_postData];
    [super appendPostData:[DEFAULT_END_STRING dataUsingEncoding:_stringEncoding]];
    NSString *endItemBoundary = [NSString stringWithFormat:@"--%@--", _boundary];
    [super appendPostData:[endItemBoundary dataUsingEncoding:_stringEncoding]];
    [super appendPostData:[DEFAULT_END_STRING dataUsingEncoding:_stringEncoding]];
}

-(NSString *)createBoundary{
    //NSDate *now = [NSDate date];
    //NSTimeInterval timeInterval = [now timeIntervalSince1970];
    //NSString *boundary = [NSString stringWithFormat:@"---------------------------%f", timeInterval];
    //boundary = [boundary stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    
    /*
    NSMutableString *bound = [NSMutableString string];
    char hexArr[] = {"012345679ABCDEF"};
    for (int i=0; i<32; i++) {
        char hex = *(rand() % 15 + hexArr);
        [bound appendFormat:@"%c", hex];
    }
    return [NSString stringWithString:bound];
     */
    
    return [boundary retain];
}

-(void)startSynchronous{
    [self doPostData];
    [super startSynchronous];
}

-(void)startAsynchronous{
    [self doPostData];
    [super startAsynchronous];
}

@end
