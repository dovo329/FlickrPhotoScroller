//
//  PhotoDetail.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/13/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Model for photo detail info returned from Flickr API call

import Foundation
import UIKit

struct PhotoDetail: CustomStringConvertible {
    var title: String
    var photoDescription : String
    var authorRealName: String
    var location: String
    var dateTaken: String
    
    var description : String {
        
        var strBld = "Title: \(self.title)\n"
        strBld += "Description: \(self.photoDescription)\n"
        strBld += "Author Name: \(self.authorRealName)\n"
        strBld += "Location: \(self.location)\n"
        strBld += "Date Taken: \(self.dateTaken)\n"
        return strBld
    }
}
