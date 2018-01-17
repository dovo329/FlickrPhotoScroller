//
//  Utils.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Miscellaneous utility functions

import Foundation
import UIKit

// Concise way to display a simple alert
func simpleAlert(vc: UIViewController, title: String, message: String, ackStr: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    let okAction = UIAlertAction(title: ackStr, style: UIAlertActionStyle.default, handler:nil)
    alertController.addAction(okAction)
    vc.present(alertController, animated: true, completion: nil)
}
