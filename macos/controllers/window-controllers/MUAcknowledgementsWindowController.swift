//
//  MUAcknowledgementsWindowController.swift
//  Koan
//
//  Created by Tyler Berry on 5/10/18.
//  Copyright © 2018 3James Software. All rights reserved.
//

import Cocoa

class MUAcknowledgementsWindowController: NSWindowController
{
  override var windowNibName: String { return "MUAcknowledgementsWindow" }
  
  @IBAction func openGrowlWebPage (_ sender: Any?)
  {
    guard let url = URL (string: MUGrowlURLString) else { return }
    NSWorkspace.shared ().open (url)
  }
  
  @IBAction func openOpenSSLWebPage (_ sender: Any?)
  {
    guard let url = URL (string: MUOpenSSLURLString) else { return }
    NSWorkspace.shared ().open (url)
  }
}
