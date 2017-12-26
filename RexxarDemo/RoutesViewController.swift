//
//  RoutesViewController.swift
//  RexxarDemo
//
//  Created by Tony Li on 11/25/15.
//  Copyright © 2015 Douban.Inc. All rights reserved.
//

import UIKit

class RoutesViewController: UITableViewController {

  fileprivate let URIs = [URL(string: "douban://douban.com/rexxar_demo")!,
                          URL(string: "douban://partial.douban.com/rexxar_demo/_.s")!]

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationController?.navigationBar.isTranslucent = false;

    title = "URIs"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return URIs.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = URIs[(indexPath as NSIndexPath).row].absoluteString
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let uri = URIs[(indexPath as NSIndexPath).row]
    if (indexPath as NSIndexPath).row == 0 {

      if #available(iOS 11, *) {
        let decorator = RXRSchemeHandlerDecorator()
        let requestSchemeHandler = RXRSchemeHandler(scheme: "rexxar-request", decorators: [decorator])
        let controller = FullRXRViewController(uri: uri, htmlFileURL: nil, schemeHandlers: [requestSchemeHandler])
        navigationController?.pushViewController(controller, animated: true)
      } else {
        let controller = FullRXRViewController(uri: uri)
        navigationController?.pushViewController(controller, animated: true)
      }
    } else if (indexPath as NSIndexPath).row == 1 {
      let controller = PartialRexxarViewController(URI: uri)
      navigationController?.pushViewController(controller, animated: true)
    }
  }

}
