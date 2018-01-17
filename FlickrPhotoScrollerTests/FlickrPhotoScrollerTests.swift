//
//  FlickrPhotoScrollerTests.swift
//  FlickrPhotoScrollerTests
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//

import XCTest
@testable import FlickrPhotoScroller

class FlickrPhotoScrollerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFlickrApiUrlForLargePhotoSucceed() {
        
        // real working url to test with
        let expectedUrlStr = "https://farm5.staticflickr.com/4740/38935250244_092b54d6be_b.jpg"
        let photo = Photo(farmId: "5",
                          serverId: "4740",
                          photoId: "38935250244",
                          secret: "092b54d6be",
                          title: "test")
        do {
            let url = try JanePhotoScroller.flickrApiUrlForLarge(photo: photo)
            XCTAssert(url.absoluteString == expectedUrlStr, "url: \(url.absoluteString) != expectedUrl: \(expectedUrlStr)")
        } catch {
            let nsError = error as NSError
            XCTFail("flickrApiUrlForLargePhoto threw error \(nsError)")
        }
    }
    
    func testFlickrApiUrlForLargePhotoFail() {
        
        // real working url to test with
        let expectedUrlStr = "https://farm5.staticflickr.com/4740/38935250244_092b54d6be_t.jpg"
        let photo = Photo(farmId: "5",
                          serverId: "4740",
                          photoId: "38935250244",
                          secret: "092b54d6be",
                          title: "test")
        do {
            let url = try JanePhotoScroller.flickrApiUrlForLarge(photo: photo)
            XCTAssert(url.absoluteString != expectedUrlStr, "url: \(url.absoluteString) == expectedUrl: \(expectedUrlStr), but wasn't supposed to be equal")
        } catch {
            let nsError = error as NSError
            XCTFail("flickrApiUrlForLargePhoto threw error \(nsError)")
        }
    }
    
    func testFlickrApiUrlForThumbnailPhotoSucceed() {
        
        // real working url to test with
        let expectedUrlStr = "https://farm5.staticflickr.com/4740/38935250244_092b54d6be_t.jpg"
        let photo = Photo(farmId: "5",
                          serverId: "4740",
                          photoId: "38935250244",
                          secret: "092b54d6be",
                          title: "test")
        do {
            let url = try JanePhotoScroller.flickrApiUrlForThumbnail(photo: photo)
            XCTAssert(url.absoluteString == expectedUrlStr, "url: \(url.absoluteString) != expectedUrl: \(expectedUrlStr)")
        } catch {
            let nsError = error as NSError
            XCTFail("flickrApiUrlForLargePhoto threw error \(nsError)")
        }
    }
    
    func testFlickrApiUrlForThumbnailPhotoFail() {
        
        // real working url to test with
        let expectedUrlStr = "https://farm5.staticflickr.com/4740/38935250244_092b54d6be_b.jpg"
        let photo = Photo(farmId: "5",
                          serverId: "4740",
                          photoId: "38935250244",
                          secret: "092b54d6be",
                          title: "test")
        do {
            let url = try JanePhotoScroller.flickrApiUrlForThumbnail(photo: photo)
            XCTAssert(url.absoluteString != expectedUrlStr, "url: \(url.absoluteString) == expectedUrl: \(expectedUrlStr), but wasn't supposed to be equal")
        } catch {
            let nsError = error as NSError
            XCTFail("flickrApiUrlForLargePhoto threw error \(nsError)")
        }
    }
    
    func testBuildFlickrApiUrlSucceed() {
        
        let expectedUrlStr = "https://api.flickr.com/services/rest/?api_key=64c44bd385e99a804a78fd93270b8628&method=flickr.interestingness.getList&format=json&page=2&per_page=100&nojsoncallback=1"
        
        let urlParameters = [
            "method": "flickr.interestingness.getList",
            "api_key": "64c44bd385e99a804a78fd93270b8628",
            "format": "json",
            "nojsoncallback": "1",
            "page": "2",
            "per_page": "100"
        ]
        
        guard let url = JanePhotoScroller.testBuildFlickrApiUrl(urlParameters: urlParameters) else {
            XCTFail("Failed to build url")
            return
        }
        XCTAssert(url.absoluteString == expectedUrlStr, "url: \(url.absoluteString) != expectedUrl: \(expectedUrlStr)")
    }
    
    func testBuildFlickrApiUrlFail() {
        
        let expectedUrlStr = "https://api.flickr.com/services/rest/?api_key=64c44bd385e99a804a78fd93270b8628&method=flickr.interestingness.getList&format=json&page=2&per_page=100&nojsoncallback=1"
        
        let urlParameters = [
            "method": "flickr.interestingness.getList",
            "api_key": "64c44bd385e99a804a78fd93270b8628",
            "format": "json",
            "nojsoncallback": "1",
            "page": "1",
            "per_page": "100"
        ]
        
        guard let url = JanePhotoScroller.testBuildFlickrApiUrl(urlParameters: urlParameters) else {
            XCTFail("Failed to build url")
            return
        }
        XCTAssert(url.absoluteString != expectedUrlStr, "url: \(url.absoluteString) == expectedUrl: \(expectedUrlStr), but wasn't supposed to be equal")
    }
}
