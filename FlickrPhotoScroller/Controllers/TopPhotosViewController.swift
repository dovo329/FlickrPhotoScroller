//
//  TopPhotosViewController.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Shows the current "top" photos from Flickr in a scrollable grid with paging.

import UIKit

class TopPhotosViewController: BasePhotosViewController, BasePhotosViewControllerDelegate {
    
    var pageNum = 1
    var isGettingMorePhotos: Bool = false
    var selectedPhoto: Photo?
    
    // MARK: - init
    // sets this View Controller as the delegate for the BasePhotosViewController it inherits from, so that the BasePhotosVC can call the various implementation specific methods on it.  A delegate hookup is required by the BasePhotosViewController.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)   {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        self.delegate = self
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // reset flag that protects against firing off many API requests at once.  The superclass should take care of cancelled all outstanding API requests on viewDidAppear, so that we have a clean slate to work with.
        self.isGettingMorePhotos = false
    }
    
    // MARK: - BasePhotosViewControllerDelegate
    func getMorePhotos(shouldResetDataSource: Bool) {
        // protect against scrollview calling this method many times when it detects it has reached the bottom
        if (isGettingMorePhotos) {
            return
        }
        isGettingMorePhotos = true
        
        // only show the mainActivityIndicator if there aren't any photos already shown.  Otherwise, it would cover up existing photos and look ugly.
        if dataSource.count == 0 {
            mainActivityIndicator.startAnimating()
        }
        if (shouldResetDataSource) {
            dataSource.removeAll()
            pageNum = 1
        }
        flickrApiGetInterestingPhotos(
            pageNum: pageNum,
            pageSize: PhotoDataSource.pageSize,
            failure: { nsError in
                self.mainActivityIndicator.stopAnimating()
                self.isGettingMorePhotos = false
                self.currentBatchResultCount = 0
                
                print(nsError)
                simpleAlert(vc: self, title: NSLocalizedString("Error", comment: "Alert title"), message: nsError.localizedDescription, ackStr: NSLocalizedString("OK", comment: "Alert button"))                
            },
            success : { photos in
                self.mainActivityIndicator.stopAnimating()
                self.isGettingMorePhotos = false
                self.currentBatchResultCount = photos.count
                self.dataSource.append(contentsOf: photos)
                self.collectionView.reloadData()
                self.pageNum += 1
            }
        )
    }
    
    func didSelect(photo: Photo) {
        selectedPhoto = photo
        performSegue(withIdentifier: SegueId.topPhotosToPhotoCloseup, sender: nil)
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let segueId = segue.identifier else {
            print("Error, bad segue.identifier")
            return
        }
        if segueId == SegueId.topPhotosToPhotoCloseup {
            guard let destVC = segue.destination as? PhotoCloseupViewController,
                let photo = selectedPhoto
                else {
                    print("Error, bad segue.destination or selectedPhoto")
                    return
            }
            destVC.photo = photo
            
        } else {
            print("Error, unknown segue id of \(segueId)")
        }
    }
}
