//
//  Photo.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Model for photo info returned from Flickr API calls

import Foundation

struct Photo {
    var farmId: String
    var serverId: String
    var photoId : String
    var secret: String
    var title: String
}
