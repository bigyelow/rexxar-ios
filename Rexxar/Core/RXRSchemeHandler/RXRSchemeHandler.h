//
//  RXRSchemeHandler.h
//  Rexxar
//
//  Created by bigyelow on 24/12/2017.
//  Copyright © 2017 Douban Inc. All rights reserved.
//

@import Foundation;
@import WebKit;

NS_ASSUME_NONNULL_BEGIN
@interface RXRSchemeHandler : NSObject <WKURLSchemeHandler>

@property (nonatomic, readonly, nullable) NSString *scheme;

- (instancetype)initWithScheme:(nullable NSString *)scheme;

@end
NS_ASSUME_NONNULL_END
