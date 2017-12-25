//
//  RXRSchemeHandler.m
//  Rexxar
//
//  Created by bigyelow on 24/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRSchemeHandler.h"

@implementation RXRSchemeHandler

- (instancetype)initWithScheme:(NSString *)scheme
{
  if (self = [super init]) {
    _scheme = [scheme copy];
  }
  return self;
}

#pragma mark - WKURLSchemeHandler

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask NS_AVAILABLE_IOS(11.0)
{
  if (![urlSchemeTask.request.URL.scheme isEqualToString:_scheme]) {
    return;
  }
  

}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask NS_AVAILABLE_IOS(11.0)
{

}
@end
