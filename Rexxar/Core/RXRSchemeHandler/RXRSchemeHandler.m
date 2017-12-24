//
//  RXRSchemeHandler.m
//  Rexxar
//
//  Created by bigyelow on 24/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRSchemeHandler.h"

static NSString *rxrRequestScheme = @"rexxar-request";

@implementation RXRSchemeHandler

#pragma mark - WKURLSchemeHandler

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask NS_AVAILABLE_IOS(11.0)
{
  if (![urlSchemeTask.request.URL.scheme isEqualToString:rxrRequestScheme]) {
    return;
  }
  

}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask NS_AVAILABLE_IOS(11.0)
{

}
@end