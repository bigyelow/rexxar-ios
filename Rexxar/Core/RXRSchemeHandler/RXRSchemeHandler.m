//
//  RXRSchemeHandler.m
//  Rexxar
//
//  Created by bigyelow on 24/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRSchemeHandler.h"
#import "RXRSchemeHandlerDecorator.h"
#import "RXRURLSessionDemux.h"

@interface RXRSchemeHandler () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionTask *dataTask;
@property (nonatomic, copy) NSArray *modes;
@property (nonatomic, class, readonly) RXRURLSessionDemux *sharedDemux;
@property (nonatomic, strong) id<WKURLSchemeTask> urlSchemeTask NS_AVAILABLE_IOS(11.0);

@end

@implementation RXRSchemeHandler

- (instancetype)initWithScheme:(NSString *)scheme
                    decorators:(NSArray<RXRSchemeHandlerDecorator *> *)decorators;

{
  if (self = [super init]) {
    _scheme = [scheme copy];
    _decorators = [decorators copy];
  }
  return self;
}

#pragma mark - Properties

+ (RXRURLSessionDemux *)sharedDemux
{
  static dispatch_once_t onceToken;
  static RXRURLSessionDemux *demux;

  dispatch_once(&onceToken, ^{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    demux = [[RXRURLSessionDemux alloc] initWithSessionConfiguration:sessionConfiguration];
  });

  return demux;
}

#pragma mark - WKURLSchemeHandler

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask NS_AVAILABLE_IOS(11.0)
{
  if (![urlSchemeTask.request.URL.scheme isEqualToString:_scheme]) {
    return;
  }

  NSURLRequest *request = [urlSchemeTask.request copy];
  for (RXRSchemeHandlerDecorator *decorator in _decorators) {
    request = [decorator decoratedRequestFromRequest:request];
  }

  // 由于在 iOS9 及一下版本对 WKWebView 缓存支持不好，所有的请求不使用缓存
  NSMutableURLRequest *newRequest;
  if ([[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] == NSOrderedAscending) {
    newRequest = [request mutableCopy];
    [newRequest setValue:nil forHTTPHeaderField:@"If-None-Match"];
    [newRequest setValue:nil forHTTPHeaderField:@"If-Modified-Since"];
    request = [newRequest copy];
  }

  // Start dataTask
  NSMutableArray *modes = [NSMutableArray array];
  [modes addObject:NSDefaultRunLoopMode];

  NSString *currentMode = [[NSRunLoop currentRunLoop] currentMode];
  if (currentMode != nil && ![currentMode isEqualToString:NSDefaultRunLoopMode]) {
    [modes addObject:currentMode];
  }
  self.modes = modes;
  self.urlSchemeTask = urlSchemeTask;
  self.dataTask = [[[self class] sharedDemux] dataTaskWithRequest:request delegate:self modes:self.modes];
  [_dataTask resume];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask NS_AVAILABLE_IOS(11.0)
{
  urlSchemeTask = nil;
  self.urlSchemeTask = nil;
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
  if (error) {
    [_urlSchemeTask didFailWithError:error];
  }
  else {
    [_urlSchemeTask didFinish];
  }
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  [_urlSchemeTask didReceiveResponse:response];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  [_urlSchemeTask didReceiveData:data];
}

@end
