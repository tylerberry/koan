//
//  MUConditionsPreferencesViewController.swift
//  Koan
//
//  Created by Tyler Berry on 5/19/18.
//  Copyright © 2018 3James Software. All rights reserved.
//

import Cocoa

class MUConditionsPreferencesViewController: NSViewController, MASPreferencesViewController
{
  override var nibName: String? { return "MUConditionsPreferencesView" }
  override var identifier: String?
  {
    get { return _identifier }
    set { _identifier = newValue }
  }
  
  var _identifier: String? = "conditions"
  var toolbarItemImage: NSImage { return NSImage (named: NSImageNameCaution)! }
  var toolbarItemLabel: String { return NSLocalizedString (MULPreferencesConditions, comment: "") }
  
  var conditions = UserDefaults.standard.array (forKey: MUPConditions)
}
