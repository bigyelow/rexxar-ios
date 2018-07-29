//
//  RXRURLSchemeHandler.swift
//  Rexxar
//
//  Created by bigyelow on 2018/7/24.
//  Copyright © 2018 Douban Inc. All rights reserved.
//

import UIKit

private let isMainRequestKey = "is_main_request"

private let rexxarErrorDomain = "rexxar_error_domain"
private let rexxarErrorMessageKey = "rexxar_error_message"

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
    guard let rexxarURL = urlSchemeTask.request.url else {
      assert(false)
      return
    }

    guard var comp = URLComponents(url: rexxarURL, resolvingAgainstBaseURL: true) else { return }

    if let items = comp.queryItems,
      items.filter({ (item) -> Bool in return item.name == isMainRequestKey && item.value == "1"}).count > 0 {
      // If is `main request`, fetch data directly and return it to WKWebView by calling urlSchemeTask's callback.

      comp.queryItems?.removeItemByName(isMainRequestKey)
      comp.scheme = comp.scheme?.httpScheme
      guard let url = comp.url else { return }
      sendSimpleRequest(with: url, for: urlSchemeTask)

    } else if let items = comp.queryItems,
      items.filter({ (item) -> Bool in return item.name == RXRURLQueryOriginalURLKey }).count > 0 {
      // If is request for loading local html

      let filteredItems = items.filter({ (item) -> Bool in return item.name == RXRURLQueryOriginalURLKey })
      guard filteredItems.count > 0 else { return }
      guard let originalFileURLStr = filteredItems[0].value else { return}
      guard var fileComp = URLComponents(string: originalFileURLStr) else { return }

      // Remove uri
      fileComp.queryItems?.removeItemByName(RXRURLQueryURIKey)

      guard var fileLocation = fileComp.url?.absoluteString else { return }
      if let range = fileLocation.range(of: "file://") {
        fileLocation.removeSubrange(range)
      }
      guard FileManager.default.fileExists(atPath: fileLocation) else { return }

      // Start to load local file
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: fileLocation))
        complete(with: data, response: response(with: urlSchemeTask.request.url!), error: nil, for: urlSchemeTask)
      }
      catch {
        print(error)
        complete(with: nil,
                 response: nil,
                 error: NSError(domain: rexxarErrorDomain, code: 1, userInfo: [rexxarErrorMessageKey: error.localizedDescription]),
                 for: urlSchemeTask)
      }

    } else if comp.url != nil {
      // If is `js request` from html, check if it needs some decoration.

      if let queryItems = comp.queryItems {
        for item in queryItems {
          if item.name == RXRURLQueryHostKey {
            comp.host = item.value
            comp.queryItems?.remove(item, ignoreItemValue: false)
          } else if item.name == RXRURLQuerySchemeKey {
            comp.scheme = item.value
            comp.queryItems?.remove(item, ignoreItemValue: false)
          } else if item.name == RXRURLQueryPortKey && item.value != nil {
            comp.port = Int(item.value!)
            comp.queryItems?.remove(item, ignoreItemValue: false)
          }
        }
        comp.queryItems = (comp.queryItems ?? []).count > 0 ? comp.queryItems : nil
      }

      // Decorate js request if needed
      print("js_request_url = \(comp.url?.absoluteString ?? "")")

      if let url = comp.url, let delegate = delegate {
        delegate.sendRequest(urlSchemeTask.request.copied(with: url)) { [weak self] (data, response, error) in
          self?.complete(with: data, response: response, error: error, for: urlSchemeTask)
        }
      }
    }
  }

  public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

  }

  private func response(with url: URL) -> HTTPURLResponse? {
    return HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)
  }

  private func sendSimpleRequest(with url: URL, for urlSchemeTask: WKURLSchemeTask) {
    URLSession(configuration: URLSessionConfiguration.default).dataTask(with: url) { [weak self] (data, response, error) in
      self?.complete(with: data, response: response, error: error, for: urlSchemeTask)
      }.resume()
  }

  private func complete(with data: Data?, response: URLResponse?, error: Error?, for urlSchemeTask: WKURLSchemeTask) {
    // Use serial queue to avoid potential dead lock of multiple urlSchemeTasks.
    DispatchQueue(label: "rexxar_scheme_handler").async {
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
}

@available(iOS 11.0, *)
@objc public extension NSURLRequest {

  /// http(s) request to rexttp(s) request
  public var remoteRexttpMode: NSURLRequest? {
    guard let url = url else { return nil }
    guard let comp = NSURLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }

    // Change scheme
    if comp.scheme != nil && !comp.scheme!.isHttpSet {
      assert(false, "Main request should be scheme of `http` or `https`")
      return nil
    }
    comp.scheme = comp.scheme!.rexttpScheme

    // Add is_main_request=1
    let mainQueryItem = URLQueryItem(name: isMainRequestKey, value: "1")
    if var queryItems = comp.queryItems {
      queryItems.append(mainQueryItem)
      comp.queryItems = queryItems
    } else {
      comp.queryItems = [mainQueryItem]
    }

    guard let customURL = comp.url else { return nil }
    return copied(with: customURL)
  }

  /// local file request to rexttp(s) request
  public var localRexttpMode: NSURLRequest? {
    guard let url = url else { return nil }
    guard var comp = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }

    if comp.scheme != nil && !comp.scheme!.isLocalScheme {
      assert(false, "Local file request should be scheme of `file`")
      return nil
    }

    for item in comp.queryItems ?? [] {
      if item.name == RXRURLQuerySchemeKey {
        comp.scheme = item.value
      } else if item.name == RXRURLQueryHostKey {
        comp.host = item.value
      } else if item.name == RXRURLQueryPortKey && item.value != nil {
        comp.port = Int(item.value!)
      }
    }
    comp.queryItems?.removeItemByName(RXRURLQuerySchemeKey)
    comp.queryItems?.removeItemByName(RXRURLQueryPortKey)
    comp.queryItems?.removeItemByName(RXRURLQueryHostKey)

    if let originalURL = url.absoluteString.removingPercentEncoding {
      let originalItem = URLQueryItem(name: RXRURLQueryOriginalURLKey, value: originalURL)
      if var queryItems = comp.queryItems {
        queryItems.append(originalItem)
        comp.queryItems = queryItems
      } else {
        comp.queryItems = [originalItem]
      }
    }

    guard let customURL = comp.url else { return nil }
    return copied(with: customURL)
  }

  fileprivate func copied(with url: URL) -> NSURLRequest {
    return URLRequest(url: url, cachePolicy: self.cachePolicy, timeoutInterval: self.timeoutInterval) as NSURLRequest
  }
}

@available(iOS 11.0, *)
fileprivate extension URLRequest {
  func copied(with url: URL) -> URLRequest {
    return (self as NSURLRequest).copied(with: url) as URLRequest
  }
}

@available(iOS 11.0, *)
fileprivate extension Array where Element == URLQueryItem {
  mutating func remove(_ item: URLQueryItem, ignoreItemValue: Bool) {
    guard let index = self.index(where: { (pItem) -> Bool in
      return ignoreItemValue ? pItem.name == item.name : pItem.name == item.name && pItem.value == item.value
    }) else { return }

    remove(at: index)
  }

  mutating func removeItemByName(_ name: String) {
    guard let index = self.index(where: { (pItem) -> Bool in pItem.name == name}) else { return }
    remove(at: index)
  }
}

@available(iOS 11.0, *)
fileprivate extension String {
  /// rexttp, rexttps to http, https
  var httpScheme: String? {
    if let rexttp = RXRConfig.rexxarHttpScheme, self == rexttp {
      return "http"
    } else if let rexttps = RXRConfig.rexxarHttpsScheme, self == rexttps {
      return "https"
    } else {
      assert(false, "Need configure `rexxarHttpScheme` or `rexxarHttpsScheme`")
      return nil
    }
  }

  /// http, https, file to rexttp, rexttps
  var rexttpScheme: String? {
    if let rexttp = RXRConfig.rexxarHttpScheme, self.lowercased() == "http" {
      return rexttp
    } else if let rexttps = RXRConfig.rexxarHttpScheme, self.lowercased() == "https" {
      return rexttps
    } else {
      assert(false, "Only support http or https")
      return nil
    }
  }

  var isHttpSet: Bool {
    return ["http", "https"].contains(self.lowercased())
  }

  var isLocalScheme: Bool {
    return self.lowercased() == "file"
  }
}
