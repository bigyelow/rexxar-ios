//
//  RXRSchemeHandlerDecorator.m
//  Rexxar
//
//  Created by bigyelow on 26/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRSchemeHandlerDecorator.h"
#import "RXRURLRequestSerialization.h"

@interface RXRSchemeHandlerDecorator ()

@property (nonatomic, strong) RXRHTTPRequestSerializer *requestSerializer;

@end

@implementation RXRSchemeHandlerDecorator

- (instancetype)init
{
  if (self = [super init]) {
    _requestSerializer = [[RXRHTTPRequestSerializer alloc] init];
  }
  return self;
}

- (NSURLRequest *)decoratedRequestFromRequest:(NSURLRequest *)request
{
  if (!request) {
    return nil;
  }

  NSMutableURLRequest *mutableRequest = [request mutableCopy];

  // Request headers
  NSDictionary *decoratingHeaders = [self headersForRequest:request];
  [decoratingHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]]){
      [mutableRequest setValue:obj forHTTPHeaderField:key];
    }
  }];

  // Request url parameters
  NSMutableDictionary *decoratingParams = [[self parametersForRequest:request] mutableCopy];
  [self _rxr_addQuery:mutableRequest.URL.query toParameters:decoratingParams];

  // Note: mutableRequest.URL.query has been added to the paramters, _requestSerializer will generate a new NSURLRequest
  // object from the parameters every time when it decorates a request. If we don't remove query from URL, request may
  // contain duplicated query string if the original request is decorated more than 2 times.
  NSURLComponents *comp = [[NSURLComponents alloc] initWithURL:mutableRequest.URL resolvingAgainstBaseURL:NO];
  comp.query = nil;
  mutableRequest.URL = comp.URL;

  return [_requestSerializer requestBySerializingRequest:mutableRequest
                                          withParameters:decoratingParams
                                                   error:nil];
}

#pragma mark - Methods can be overriden

- (NSDictionary *)headersForRequest:(NSURLRequest *)request
{
  return nil;
}

- (NSDictionary *)parametersForRequest:(NSURLRequest *)request
{
  return nil;
}

#pragma mark - Private methods

- (void)_rxr_addQuery:(NSString *)query toParameters:(NSMutableDictionary *)parameters
{
  if (!parameters) {
    return;
  }

  for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
    NSArray *keyValuePair = [pair componentsSeparatedByString:@"="];
    if (keyValuePair.count != 2) {
      continue;
    }

    NSString *key = [keyValuePair[0] stringByRemovingPercentEncoding];
    if (parameters[key] == nil) {
      parameters[key] = [keyValuePair[1] stringByRemovingPercentEncoding];
    }
  }
}

@end
