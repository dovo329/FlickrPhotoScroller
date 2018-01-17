//
//  PhotoCloseupViewController.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/13/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Shows a zoomable, scrollable large version of a Flickr photo.  Also shows about photo information in a textView.
//
//  Safe Area constraints don't appear to work correctly on iOS 10, but they do on iOS 11.  Instead, on iOS 10, the Safe Area seems to be the size of the entire screen instead of it subtracting the status, navitem, and tab bars from the screen height.

import Foundation
import UIKit

class PhotoCloseupViewController: UIViewController {
    
    var photo: Photo?
    
    @IBOutlet weak var photoActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let photo = photo else {
            print("Error, no photo provided for PhotoCloseupViewController. Exiting")
            dismiss(animated: true, completion: nil)
            return
        }
        
       // Detect orientation change in order to reset zoom on scrollView
        NotificationCenter.default.addObserver(forName: .UIDeviceOrientationDidChange,
                                               object: nil,
                                               queue: .main,
                                               using: didRotate)
        
        textView.text = ""

        // pull down large version of the provided photo
        self.photoActivityIndicator.startAnimating()
        do {
            let photoUrl = try flickrApiUrlForLarge(photo: photo)
            
            self.imageView.af_setImage(
                withURL: photoUrl,
                completion: { response in
                    self.photoActivityIndicator.stopAnimating()
                }
            )
            
        } catch {
            let nsError = error as NSError
            self.photoActivityIndicator.stopAnimating()
            print(nsError)
            simpleAlert(vc: self, title: NSLocalizedString("Error", comment: "Alert title"), message: nsError.localizedDescription, ackStr: NSLocalizedString("OK", comment: "Alert button"))
        }
        
        // pull down detailed text information about the photo
        textActivityIndicator.startAnimating()
        flickrApiGetDetailedPhotoInfo(
            photo: photo,
            failure: {nsError in
                self.textActivityIndicator.stopAnimating()
                print(nsError)
                simpleAlert(vc: self, title: NSLocalizedString("Error", comment: "Alert title"), message: nsError.localizedDescription, ackStr: NSLocalizedString("OK", comment: "Alert button"))
            },
            success: {photoDetail in
                self.textActivityIndicator.stopAnimating()
                self.textView.text = String(describing: photoDetail)
        }
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    // reset zoomScale on scrollView on valid orientation change because otherwise the photo display gets messed up. Also reset scroll position in textView because that can also get messed up
    lazy var didRotate: (Notification) -> Void = { notification in
        switch UIDevice.current.orientation {
        case .landscapeLeft, .landscapeRight, .portrait:
            self.scrollView.zoomScale = 1.0
            self.textView.contentOffset = CGPoint(x: 0.0, y: 0.0)
        case .faceUp, .faceDown, .unknown, .portraitUpsideDown:
            break
        }
    }
}

// MARK: - UIScrollViewDelegate

// Make scrollview zoomable by providing a viewForZomming
extension PhotoCloseupViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
}
