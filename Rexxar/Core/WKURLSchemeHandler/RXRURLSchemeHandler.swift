//
//  RXRURLSchemeHandler.swift
//  Rexxar
//
//  Created by bigyelow on 2018/7/24.
//  Copyright © 2018 Douban Inc. All rights reserved.
//

import UIKit

private let isMainRequestKey = "is_main_request"

@available(iOS 11.0, *)
public class RXRURLSchemeHandler: NSObject, WKURLSchemeHandler {
  public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let rexxarURL = urlSchemeTask.request.url, let originalScheme = rexxarURL.scheme?.originalScheme else {
      assert(false, "URL or scheme error")
      return
    }

    guard var comp = URLComponents(url: rexxarURL, resolvingAgainstBaseURL: true) else { return }
    comp.scheme = originalScheme

    // check if is main request
    if let url = comp.url, let items = comp.queryItems, items.filter({ (item) -> Bool in
      return item.name == isMainRequestKey && item.value == "1"
    }).count > 0 {
      URLSession(configuration: URLSessionConfiguration.default).dataTask(with: url) { (data, response, error) in
        if let error = error {
          urlSchemeTask.didFailWithError(error)
          return
        }

        if let response = response {
          urlSchemeTask.didReceive(response)
        }
        if let data = data {
          urlSchemeTask.didReceive(data)
        }
        urlSchemeTask.didFinish()
      }.resume()
    }
  }

  public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

  }
}

@available(iOS 11.0, *)
fileprivate extension String {
  var originalScheme: String? {
    if let rexttp = RXRConfig.rexxarHttpScheme, self == rexttp {
      return "http"
    } else if let rexttps = RXRConfig.rexxarHttpsScheme, self == rexttps {
      return "https"
    } else {
      return nil
    }
  }
}

@available(iOS 11.0, *)
@objc public extension NSURLRequest {
  public var customMainRequest: NSURLRequest? {
    guard let url = url else { return nil }
    guard let comp = NSURLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }

    // change scheme
    comp.scheme = RXRConfig.rexxarHttpScheme

    // add is_main_request=1
    let mainQueryItem = URLQueryItem(name: isMainRequestKey, value: "1")
    if var queryItems = comp.queryItems {
      queryItems.append(mainQueryItem)
      comp.queryItems = queryItems
    } else {
      comp.queryItems = [mainQueryItem]
    }

    guard let customURL = comp.url else { return nil }
    return NSURLRequest(url: customURL)
  }
}
