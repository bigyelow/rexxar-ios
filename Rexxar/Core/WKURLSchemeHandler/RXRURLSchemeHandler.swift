//
//  RXRURLSchemeHandler.swift
//  Rexxar
//
//  Created by bigyelow on 2018/7/24.
//  Copyright © 2018 Douban Inc. All rights reserved.
//

import UIKit

@available(iOS 11.0, *)
public class RXRURLSchemeHandler: NSObject, WKURLSchemeHandler {
  public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let rexxarURL = urlSchemeTask.request.url, let rexxarScheme = rexxarURL.scheme else { return }
    guard let customScheme = RXRConfig.customURLScheme, rexxarScheme == customScheme else {
      assert(false, "`customScheme` error")
      return
    }

    // change rexxarScheme to https
    var comp = URLComponents(url: rexxarURL, resolvingAgainstBaseURL: true)
    comp?.scheme = "https"
    guard let url = comp?.url else { return }
    let request = URLRequest(url: url)

    // FRD_FIXME
    print(request.url?.absoluteString)
  }

  public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {

  }
}
