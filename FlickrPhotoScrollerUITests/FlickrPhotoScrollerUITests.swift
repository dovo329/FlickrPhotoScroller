//
//  FlickrPhotoScrollerUITests.swift
//  FlickrPhotoScrollerUITests
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//

import XCTest

class FlickrPhotoScrollerUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNoUserNameAlert() {
        
        let app = XCUIApplication()
        app.tabBars.buttons["User Photos"].tap()
        app.searchFields["Enter Flickr Username"].tap()
        app.typeText("\r")
        
        sleep(1)
        XCTAssert(XCUIApplication().alerts["Error"].exists, "Alert for no username entered was supposed to popup but didn't")
    }
}
