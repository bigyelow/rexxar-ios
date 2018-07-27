//
//  RXRURLSchemeHandler.swift
//  Rexxar
//
//  Created by bigyelow on 2018/7/24.
//  Copyright © 2018 Douban Inc. All rights reserved.
//

import UIKit

private let isMainRequestKey = "is_main_request"
private let schemeKey = "_rexttp_scheme"  // Server needs support this query_name.
private let hostKey = "_rexttp_host"  // Server needs support this query_name.
private let portKey = "_rexttp_port"  // Server needs support this query_name.

@available(iOS 11.0, *)
@objc public protocol RXRURLSchemeHandlerDelegate {
  func sendRequest(_ request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}

@available(iOS 11.0, *)
public class RXRURLSchemeHandler: NSObject, WKURLSchemeHandler {
  private weak var delegate: RXRURLSchemeHandlerDelegate?

  @objc public init(delegate: RXRURLSchemeHandlerDelegate?) {
    self.delegate = delegate
    super.init()
  }

  public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let rexxarURL = urlSchemeTask.request.url, let originalScheme = rexxarURL.scheme?.originalScheme else {
      assert(false, "URL or scheme error")
      return
    }

    guard var comp = URLComponents(url: rexxarURL, resolvingAgainstBaseURL: true) else { return }
    comp.scheme = originalScheme

    // If is `main request`, fetch data directly and return it to WKWebView by calling urlSchemeTask's callback.
    if let url = comp.url,
      let items = comp.queryItems,
      items.filter({ (item) -> Bool in return item.name == isMainRequestKey && item.value == "1"}).count > 0 {
      sendSimpleRequest(with: url, for: urlSchemeTask)
    } else if comp.url != nil {  // If is `js request` from html, check if it needs some decoration.
      // Replace scheme, host, port if needed
      if var queryItems = comp.queryItems {
        for item in queryItems {
          if item.name == hostKey {
            comp.host = item.value
            queryItems.remove(at: queryItems.index(of: item)!)
            comp.queryItems = queryItems.count > 0 ? queryItems : nil
          } else if item.name == schemeKey {
            comp.scheme = item.value
            queryItems.remove(at: queryItems.index(of: item)!)
            comp.queryItems = queryItems.count > 0 ? queryItems : nil
          } else if item.name == portKey && item.value != nil {
            comp.port = Int(item.value!)
            queryItems.remove(at: queryItems.index(of: item)!)
            comp.queryItems = queryItems.count > 0 ? queryItems : nil
          }
        }
      }

      // Decorate js request if needed
      print("js_request_url = \(comp.url?.absoluteString ?? "")")

      if let url = comp.url, let delegate = delegate {
        let request = URLRequest(url: url,
                                 cachePolicy: urlSchemeTask.request.cachePolicy,
                                 timeoutInterval: urlSchemeTask.request.timeoutInterval)
        delegate.sendRequest(request) { [weak self] (data, response, error) in
          self?.complete(with: data, response: response, error: error, for: urlSchemeTask)
        }
      }
    }
  }

  public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

  }

  private func sendSimpleRequest(with url: URL, for urlSchemeTask: WKURLSchemeTask) {
    URLSession(configuration: URLSessionConfiguration.default).dataTask(with: url) { [weak self] (data, response, error) in
      self?.complete(with: data, response: response, error: error, for: urlSchemeTask)
      }.resume()
  }

  private func complete(with data: Data?, response: URLResponse?, error: Error?, for urlSchemeTask: WKURLSchemeTask) {
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

    // Change scheme
    comp.scheme = RXRConfig.rexxarHttpScheme

    // Add is_main_request=1
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
