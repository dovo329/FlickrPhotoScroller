//
//  FlickrAPI.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Contains all Flickr API calls.  This is similar to how retrofit on Android does things, although one difference is I am parsing the JSON response in this file and returning a model whereas retrofit would give back a POJO structure.

import Foundation
import Alamofire
import SwiftyJSON

fileprivate let FlickrApiBaseUrlStr = "https://api.flickr.com/services/rest/"

// Utility function
fileprivate func flickrApiKey() -> String {
    // Credit to the original source for this technique at
    // http://blog.lazerwalker.com/blog/2014/05/14/handling-private-api-keys-in-open-source-ios-apps
    guard let filePath = Bundle.main.path(forResource: "ApiKeys", ofType: "plist") else {
        fatalError("Unable to access ApiKeys.plist")
    }
    guard let plist = NSDictionary(contentsOfFile:filePath) else {
        fatalError("Error accessing \(filePath)")
    }
    guard let value = plist.object(forKey: "FLICKR_API_KEY") as? String else {
        fatalError("Error accessing FLICKR_API_KEY")
    }
    return value
}

// Utility function
fileprivate func buildFlickrApiUrl(urlParameters: [String: String]) -> URL? {
    guard let baseUrl = URL(string: FlickrApiBaseUrlStr) else {
        return nil
    }
    guard var urlComponents = URLComponents(url: baseUrl, resolvingAgainstBaseURL: true) else {
        return nil
    }
    
    let queryItems = urlParameters.flatMap({ URLQueryItem(name: $0.key, value: $0.value) })
    urlComponents.queryItems = queryItems
    guard let url = urlComponents.url else {
        return nil
    }
    return url
}

// Testable wrapper around utility function so that unit tests can get to it.  It's not possible to unit test a private function, but it is possible to test an internal wrapper around a private function.  I would rather do this than make FlickrAPI a framework.  I figure with "test" as a prefix to the function, the purpose of the function is obvious and wouldn't be accidentally used in actual app code.  It would just be used for unit tests.
func testBuildFlickrApiUrl(urlParameters: [String: String]) -> URL? {
    return buildFlickrApiUrl(urlParameters: urlParameters)
}

// uses https://www.flickr.com/services/api/flickr.interestingness.getList.html to return an array of the top photos for the specified page.  "interestingness" is apparently determined by a "Magic Donkey".  "It is based on a secret formula of views, favourites and comments."  https://www.flickr.com/groups/api/discuss/72157629327661728/?search=top+photo
func flickrApiGetInterestingPhotos(
    pageNum: Int,
    pageSize: Int,
    failure fail : @escaping (NSError) -> (),
    success succeed: @escaping ([Photo]) -> ()) {
    
    // build url
    let urlParameters = [
        "method": "flickr.interestingness.getList",
        "api_key": flickrApiKey(),
        "format": "json",
        "nojsoncallback": "1",
        "page": String(pageNum),
        "per_page": String(pageSize)
    ]
    guard let url = buildFlickrApiUrl(urlParameters: urlParameters) else {
        fail(APIError.createUrlError as NSError)
        return
    }
    
    // make api call to get "top" (most interesting) photos
    Alamofire.request(url, method: .get).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
            // example response
            //    {
            //    "photos": {
            //        "page": 1,
            //        "pages": 5,
            //        "perpage": 100,
            //        "total": 500,
            //        "photo": [
            //        {
            //        "id": "38935250244",
            //        "owner": "130108065@N08",
            //        "secret": "092b54d6be",
            //        "server": "4740",
            //        "farm": 5,
            //        "title": "misty.morning.rise.up",
            //        "ispublic": 1,
            //        "isfriend": 0,
            //        "isfamily": 0
            //        },
            //        {
            //        "id": "27869878289",
            //        "owner": "62440012@N04",
            //        "secret": "5e9929c4b1",
            //        "server": "4752",
            //        "farm": 5,
            //        "title": "Incoming",
            //        "ispublic": 1,
            //        "isfriend": 0,
            //        "isfamily": 0
            //        }
            //        ]
            //    },
            //    "stat": "ok"
            //}
            
            let json = JSON(value)
            
            var photosArr : [Photo] = []
            
            for (_, photoJson) in json["photos"]["photo"] {
                if
                    let farmId = photoJson["farm"].int,
                    let serverId = photoJson["server"].string,
                    let photoId = photoJson["id"].string,
                    let secret = photoJson["secret"].string,
                    let title = photoJson["title"].string {

                    // populate our return array with new photo object
                    let photo = Photo(farmId: String(farmId), serverId: serverId, photoId: photoId, secret: secret, title: title)
                    photosArr.append(photo)
                } else {
                    fail(APIError.jsonFormatError as NSError)
                    return
                }
            }
            succeed(photosArr)
            return
            
        case .failure(let error as NSError):
            callFailure(failure: fail, nsError: error)
        }
    }
}

// private method used by flickrApiUrlFor<WhateverSize>(photo:) methods
fileprivate func flickrApiUrlFor(photo: Photo, sizeLetter: String) throws -> URL {
    
    // photo url will be in this format
    //https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
    let urlStr = "https://farm\(photo.farmId).staticflickr.com/\(photo.serverId)/\(photo.photoId)_\(photo.secret)_\(sizeLetter).jpg"
    
    guard let url = URL(string: urlStr) else {
        throw (APIError.createUrlError as NSError)
    }
    return url
}

// returns url for thumbnail image for photo
func flickrApiUrlForThumbnail(photo: Photo) throws -> URL {
    do {
        let url = try flickrApiUrlFor(photo: photo, sizeLetter: "t")
        return url
    } catch {
        throw error
    }
}

// returns url for large image for photo
func flickrApiUrlForLarge(photo: Photo) throws -> URL {
    do {
        let url = try flickrApiUrlFor(photo: photo, sizeLetter: "b")
        return url
    } catch {
        throw error
    }
}

// uses https://www.flickr.com/services/api/flickr.people.findByUsername.html to find a username on Flickr and get nsuserid if it exists.  We need the nsuserid for other Flickr API calls.
func flickrApiFindBy(
    username : String,
    failure fail : @escaping (NSError) -> () = {error in },
    success succeed: @escaping (User) -> () = {user in }) {
    
    // build url
    let urlParameters = [
        "method": "flickr.people.findByUsername",
        "api_key": flickrApiKey(),
        "format": "json",
        "nojsoncallback": "1",
        "username": username
    ]
    guard let url = buildFlickrApiUrl(urlParameters: urlParameters) else {
        fail(APIError.createUrlError as NSError)
        return
    }
    
    // make api call to find username and get user info
    Alamofire.request(url, method: .get).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
            let json = JSON(value)
            
            // example response
            //
            // success:
            // {
            //    "user": {
            //        "id": "155595619@N02",
            //        "nsid": "155595619@N02",
            //        "username": {
            //            "_content": "dovo329"
            //        }
            //    },
            //    "stat": "ok"
            // }
            //
            // fail:
            // {
            //    "stat": "fail",
            //    "code": 1,
            //    "message": "User not found"
            // }
            
            if let stat = json["stat"].string {
                if stat != "ok" {
                    if let message = json["message"].string {
                        fail(APIError.customError(message) as NSError)
                    } else {
                        fail(APIError.jsonFormatError as NSError)
                    }
                    return
                }
            }
            
            if let username = json["user"]["username"]["_content"].string,
                let nsid = json["user"]["nsid"].string {
                
                let user = User(username: username, nsid: nsid)
                succeed(user)
            } else {
                
                fail(APIError.jsonFormatError as NSError)
            }
            
        case .failure(let error as NSError):
            callFailure(failure: fail, nsError: error)
        }
    }
}

// uses https://www.flickr.com/services/api/flickr.people.getPhotos.html to get photos for a flickr user_id (nsuserid)
func flickrApiGetPhotosFor(
    nsUserId : String,
    pageNum: Int,
    pageSize: Int,
    failure fail : @escaping (NSError) -> () = {error in },
    success succeed: @escaping ([Photo]) -> () = {photos in }) {
    
    // build url
    let urlParameters = [
        "method": "flickr.people.getPhotos",
        "api_key": flickrApiKey(),
        "format": "json",
        "nojsoncallback": "1",
        "user_id": nsUserId,
        "page": String(pageNum),
        "per_page": String(pageSize)
    ]
    guard let url = buildFlickrApiUrl(urlParameters: urlParameters) else {
        fail(APIError.createUrlError as NSError)
        return
    }
    
    // make api call to get photos for user id
    Alamofire.request(url, method: .get).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
            let json = JSON(value)
            
            //example response
            //{
            //    "photos": {
            //        "page": 1,
            //        "pages": 2,
            //        "perpage": 100,
            //        "total": "200",
            //        "photo": [
            //        {
            //        "id": "31494782395",
            //        "owner": "92549330@N04",
            //        "secret": "ce8d062ede",
            //        "server": "5504",
            //        "farm": 6,
            //        "title": "Proj03Final-REVISED-ABuxton",
            //        "ispublic": 1,
            //        "isfriend": 0,
            //        "isfamily": 0
            //        },
            //        {
            //        "id": "31348011452",
            //        "owner": "92549330@N04",
            //        "secret": "4bd81daed0",
            //        "server": "458",
            //        "farm": 1,
            //        "title": "FireworksCD_RGB_FINAL",
            //        "ispublic": 1,
            //        "isfriend": 0,
            //        "isfamily": 0
            //        }
            //        ]
            //    },
            //    "stat": "ok"
            //}
            
            var photosArr : [Photo] = []
            
            for (_, photoJson) in json["photos"]["photo"] {
                if
                    let farmId = photoJson["farm"].int,
                    let serverId = photoJson["server"].string,
                    let photoId = photoJson["id"].string,
                    let secret = photoJson["secret"].string,
                    let title = photoJson["title"].string {
                    
                    // populate our return array with new photo object
                    let photo = Photo(farmId: String(farmId), serverId: serverId, photoId: photoId, secret: secret, title: title)
                    photosArr.append(photo)
                } else {
                    fail(APIError.jsonFormatError as NSError)
                    return
                }
            }
            succeed(photosArr)
            return
            
        case .failure(let error as NSError):
            callFailure(failure: fail, nsError: error)
        }
    }
}

// uses https://www.flickr.com/services/api/flickr.photos.getInfo.html to get detailed information about a specific photo
func flickrApiGetDetailedPhotoInfo(
    photo : Photo,
    failure fail : @escaping (NSError) -> () = {error in },
    success succeed: @escaping (PhotoDetail) -> () = {photoDetail in }) {
    
    // build url
    let urlParameters = [
        "method": "flickr.photos.getInfo",
        "api_key": flickrApiKey(),
        "format": "json",
        "nojsoncallback": "1",
        "photo_id": photo.photoId,
        "secret": photo.secret
    ]
    guard let url = buildFlickrApiUrl(urlParameters: urlParameters) else {
        fail(APIError.createUrlError as NSError)
        return
    }
    
    // make api call to get detailed photo 
    Alamofire.request(url, method: .get).validate().responseJSON { response in
        switch response.result {
        case .success(let value):
            let json = JSON(value)
            
            // example response
            //
            //    {
            //    "photo": {
            //        "id": "38935250244",
            //        "secret": "092b54d6be",
            //        "server": "4740",
            //        "farm": 5,
            //        "dateuploaded": "1515738258",
            //        "isfavorite": 0,
            //        "license": "0",
            //        "safety_level": "0",
            //        "rotation": 0,
            //        "owner": {
            //            "nsid": "130108065@N08",
            //            "username": "hoffi99",
            //            "realname": "Dirk Hoffmann",
            //            "location": "Bremen, Germany",
            //            "iconserver": "5713",
            //            "iconfarm": 6,
            //            "path_alias": "hoffi99"
            //        },
            //        "title": {
            //            "_content": "misty.morning.rise.up"
            //        },
            //        "description": {
            //            "_content": "I was looking for this half a year ..."
            //        },
            //        "visibility": {
            //            "ispublic": 1,
            //            "isfriend": 0,
            //            "isfamily": 0
            //        },
            //        "dates": {
            //            "posted": "1515738258",
            //            "taken": "2018-01-11 09:09:26",
            //            "takengranularity": "0",
            //            "takenunknown": "0",
            //            "lastupdate": "1515900542"
            //        },
            //        "views": "86407",
            //        "editability": {
            //            "cancomment": 0,
            //            "canaddmeta": 0
            //        },
            //        "publiceditability": {
            //            "cancomment": 1,
            //            "canaddmeta": 0
            //        },
            //        "usage": {
            //            "candownload": 0,
            //            "canblog": 0,
            //            "canprint": 0,
            //            "canshare": 0
            //        },
            //        "comments": {
            //            "_content": "171"
            //        },
            //        "notes": {
            //            "note": []
            //        },
            //        "people": {
            //            "haspeople": 0
            //        },
            //        "tags": {
            //            "tag": [
            //            {
            //            "id": "130015252-38935250244-236343618",
            //            "author": "130108065@N08",
            //            "authorname": "hoffi99",
            //            "raw": "Hoffi99",
            //            "_content": "hoffi99",
            //            "machine_tag": 0
            //            },
            //            {
            //            "id": "130015252-38935250244-1174",
            //            "author": "130108065@N08",
            //            "authorname": "hoffi99",
            //            "raw": "architecture",
            //            "_content": "architecture",
            //            "machine_tag": 0
            //            }
            //            ]
            //        },
            //        "urls": {
            //            "url": [
            //            {
            //            "type": "photopage",
            //            "_content": "https://www.flickr.com/photos/hoffi99/38935250244/"
            //            }
            //            ]
            //        },
            //        "media": "photo"
            //    },
            //    "stat": "ok"
            //}
            
            if let authorRealName = json["photo"]["owner"]["realname"].string,
                let location = json["photo"]["owner"]["location"].string,
                let description = json["photo"]["description"]["_content"].string,
                let dateTaken = json["photo"]["dates"]["taken"].string {
                
                let photoDetail =
                    PhotoDetail(title: photo.title,
                                photoDescription: description,
                                authorRealName: authorRealName,
                                location: location,
                                dateTaken: dateTaken)
                succeed(photoDetail)
                return
            } else {
                fail(APIError.jsonFormatError as NSError)
                return
            }
            
        case .failure(let error as NSError):
            callFailure(failure: fail, nsError: error)
        }
    }        
}

// cancel all previous requests
func flickrApiCancelAllRequests() {
    Alamofire.SessionManager.default.session.getAllTasks { tasks in
        tasks.forEach { $0.cancel() }
    }
}

// Only call failure callback if error was not due to request being cancelled, because we don't want to show the user an error alert for cancelled requests
fileprivate func callFailure(failure fail: @escaping (NSError) -> (), nsError: NSError) {
    if (nsError.code != NSURLErrorCancelled) {
        fail(APIError.customError(nsError.localizedDescription) as NSError)
    }
}
