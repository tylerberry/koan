//
//  MUPlayerViewController.swift
//  Koan
//
//  Created by Tyler Berry on 5/10/18.
//  Copyright © 2018 3James Software. All rights reserved.
//

class MUPlayerViewController: MUProfileSubviewController
{
  var player: MUPlayer?
  @IBOutlet var clearTextButton: NSButton?
  
  override var nibName: String { return "MUEditPlayerView" }
  
  override func awakeFromNib()
  {
    view.autoresizingMask = .viewWidthSizable
  }
}
