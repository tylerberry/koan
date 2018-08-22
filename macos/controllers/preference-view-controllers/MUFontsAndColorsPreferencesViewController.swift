//
//  MUFontsAndColorsPreferencesViewController.swift
//  Koan
//
//  Created by Tyler Berry on 5/19/18.
//  Copyright © 2018 3James Software. All rights reserved.
//

import Cocoa

class MUFontsAndColorsPreferencesViewController: NSViewController
{
  @IBOutlet var fontRadioButtonMatrix: NSMatrix!
  
  override var nibName: String? { return "MUFontsAndColorsPreferencesView" }
  override var identifier: String?
  {
    get { return _identifier }
    set { _identifier = newValue }
  }
  
  var _identifier: String? = "fontsandcolors"
  var toolbarItemImage: NSImage { return NSImage (named: "FontsAndColors")! }
  var toolbarItemLabel: String { return NSLocalizedString (MULPreferencesFontsAndColors, comment: "") }
  
  
}
