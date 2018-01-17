//
//  ErrorTypes.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Use NSError instead of Error for API Erorrs because a print of NSError gives better info, such as the error code and domain, instead of just a string description.  Alos, NSError is what Cocoa Touch frameworks generally use.

import Foundation

enum APIError : CustomNSError, LocalizedError {

    case createUrlError
    case jsonFormatError
    case customError(String)
    
    var errorDescription: String {
        switch self {
        case .createUrlError:
            return NSLocalizedString("Failed to create Base URL", comment: "API Error")
        case .jsonFormatError:
            return NSLocalizedString("Error with JSON Format", comment: "API Error")
        case .customError(let localizedDesc):
            return localizedDesc
        }
    }
    
    var errorDomain: String {
        return Bundle.main.bundleIdentifier! + ".APIError"
    }
    
    var errorCode: Int {
        switch self {
        case .createUrlError:
            return 0
        case .jsonFormatError:
            return 1
        case .customError:
            return 2
        }
    }
    
    var errorUserInfo: [String : Any] {
        return [NSLocalizedDescriptionKey: self.errorDescription]
    }
}
