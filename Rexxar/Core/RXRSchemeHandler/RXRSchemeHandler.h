//
//  RXRSchemeHandler.h
//  Rexxar
//
//  Created by bigyelow on 24/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

@import Foundation;
@import WebKit;

@class RXRSchemeHandlerDecorator;

NS_ASSUME_NONNULL_BEGIN
@interface RXRSchemeHandler : NSObject <WKURLSchemeHandler>

@property (nonatomic, readonly, nullable) NSString *scheme;
@property (nonatomic, readonly, nullable) NSArray <RXRSchemeHandlerDecorator *> *decorators;

- (instancetype)initWithScheme:(nullable NSString *)scheme
                    decorators:(nullable NSArray<RXRSchemeHandlerDecorator *> *)decorators;

@end
NS_ASSUME_NONNULL_END
