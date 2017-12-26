//
//  RXRRequestSchemeHandlerDecorator.m
//  RexxarDemo
//
//  Created by bigyelow on 26/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

#import "RXRRequestSchemeHandlerDecorator.h"

@implementation RXRRequestSchemeHandlerDecorator

- (NSString *)schemeForRequest:(NSURLRequest *)request
{
  return @"https";
}

- (NSDictionary *)parametersForRequest:(NSURLRequest *)request
{
  return @{@"less": @(1)};
}

@end
