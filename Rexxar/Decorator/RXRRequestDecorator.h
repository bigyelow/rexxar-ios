//
//  RXRRequestDecorator.h
//  Rexxar
//
//  Created by GUO Lin on 7/1/16.
//  Copyright © 2016 Douban.Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * `RXRRequestDecorator` 是一个具体的请求装修器。
 * 通过该装修器对 Rexxar-Conntainer 中发出的请求作修改。增加其 url 参数，以及增添自定义 header。
 */
@interface RXRRequestDecorator : NSObject

@property (nonatomic, readonly) NSURLRequest *decoratedRequest;

@property (nonatomic, copy) NSURLRequest *originalRequest;
@property (nonatomic, copy) NSDictionary *decoratingHeaders;
@property (nonatomic, copy) NSDictionary *decoratingParameters;

- (instancetype)initWithDecoratingHeaders:(nullable NSDictionary *)headers
                     decoratingParameters:(nullable NSDictionary *)parameters;
@end

NS_ASSUME_NONNULL_END
