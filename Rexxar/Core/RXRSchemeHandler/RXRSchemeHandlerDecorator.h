//
//  RXRSchemeHandlerDecorator.h
//  Rexxar
//
//  Created by bigyelow on 26/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

@import Foundation;

#import "RXRSchemeHandler.h"

NS_ASSUME_NONNULL_BEGIN
@interface RXRSchemeHandlerDecorator : NSObject

- (nullable NSURLRequest *)decoratedRequestFromRequest:(nullable NSURLRequest *)request;

#pragma mark - Methods can be overriden

- (nullable NSDictionary *)headersForRequest:(nullable NSURLRequest *)request;
- (nullable NSDictionary *)parametersForRequest:(nullable NSURLRequest *)request;

@end
NS_ASSUME_NONNULL_END
