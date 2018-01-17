//
//  Constants.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/13/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Global constants.

import Foundation
import UIKit

struct SegueId {
    static let topPhotosToPhotoCloseup = "segueIdTopPhotosToPhotoCloseup"
    static let userPhotosToPhotoCloseup = "segueIdUserPhotosToPhotoCloseup"
}

struct PhotoCellColors {
    static let normalCellBackgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
}

struct PhotoDataSource {
    static let pageSize = 100
}
