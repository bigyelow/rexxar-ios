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

@interface RXRSchemeHandler ()

@property (nonatomic, strong) NSURLSessionTask *dataTask;
@property (nonatomic, copy) NSArray *modes;
@property (nonatomic, class) RXRURLSessionDemux *sharedDemux;

@end

@implementation RXRSchemeHandler

- (instancetype)initWithScheme:(NSString *)scheme requestDecorators:(NSArray<RXRSchemeHandlerDecorator *> *)decorators
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
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask NS_AVAILABLE_IOS(11.0)
{

}

//#pragma mark - NSURLSessionTaskDelegate
//
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task
//willPerformHTTPRedirection:(NSHTTPURLResponse *)response
//        newRequest:(NSURLRequest *)request
// completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler
//{
//  if ([self client] != nil && [self dataTask] == task) {
//    NSMutableURLRequest *mutableRequest = [request mutableCopy];
//    [[self class] unmarkRequestAsIgnored:mutableRequest];
//    [[self client] URLProtocol:self wasRedirectedToRequest:mutableRequest redirectResponse:response];
//
//    NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
//    [self.dataTask cancel];
//    [self.client URLProtocol:self didFailWithError:error];
//  }
//}
//
//- (void)URLSession:(NSURLSession *)session
//              task:(NSURLSessionTask *)task
//didCompleteWithError:(nullable NSError *)error
//{
//  if ([self client] != nil && (_dataTask == nil || _dataTask == task)) {
//    if (error == nil) {
//      [[self client] URLProtocolDidFinishLoading:self];
//    } else if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
//      // Do nothing.
//    } else {
//      [[self client] URLProtocol:self didFailWithError:error];
//    }
//  }
//}
//
//#pragma mark - NSURLSessionDataDelegate
//
//- (void)URLSession:(NSURLSession *)session
//          dataTask:(NSURLSessionDataTask *)dataTask
//didReceiveResponse:(NSURLResponse *)response
// completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
//{
//  if ([self client] != nil && [self dataTask] != nil && [self dataTask] == dataTask) {
//    NSHTTPURLResponse *URLResponse = nil;
//    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
//      URLResponse = (NSHTTPURLResponse *)response;
//      URLResponse = [NSHTTPURLResponse rxr_responseWithURL:URLResponse.URL
//                                                statusCode:URLResponse.statusCode
//                                              headerFields:URLResponse.allHeaderFields
//                                           noAccessControl:YES];
//    }
//
//    [[self client] URLProtocol:self
//            didReceiveResponse:URLResponse ?: response
//            cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//    completionHandler(NSURLSessionResponseAllow);
//  }
//}
//
//- (void)URLSession:(NSURLSession *)session
//          dataTask:(NSURLSessionDataTask *)dataTask
//    didReceiveData:(NSData *)data
//{
//  if ([self client] != nil && [self dataTask] == dataTask) {
//    [[self client] URLProtocol:self didLoadData:data];
//  }
//}
//
//- (void)URLSession:(NSURLSession *)session
//          dataTask:(NSURLSessionDataTask *)dataTask
// willCacheResponse:(NSCachedURLResponse *)proposedResponse
// completionHandler:(void (^)(NSCachedURLResponse *_Nullable cachedResponse))completionHandler
//{
//  if ([self client] != nil && [self dataTask] == dataTask) {
//    completionHandler(proposedResponse);
//  }
//}

@end
