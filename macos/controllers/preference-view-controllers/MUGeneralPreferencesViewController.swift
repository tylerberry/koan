//
//  MUGeneralPreferencesViewController.swift
//  Koan
//
//  Created by Tyler Berry on 5/20/18.
//  Copyright © 2018 3James Software. All rights reserved.
//

import Cocoa

class MUGeneralPreferencesViewController: NSViewController
{
  override var nibName: String? { return "MUGeneralPreferencesView" }
  override var identifier: String?
    {
    get { return _identifier }
    set { _identifier = newValue }
  }
  
  var _identifier: String? = "general"
  var toolbarItemImage: NSImage { return NSImage (named: NSImageNamePreferencesGeneral)! }
  var toolbarItemLabel: String { return NSLocalizedString (MULPreferencesGeneral, comment: "") }
  
  
}
