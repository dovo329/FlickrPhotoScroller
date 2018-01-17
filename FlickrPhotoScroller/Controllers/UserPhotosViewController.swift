//
//  UserPhotosViewController.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Displays the photos for a Flickr username provided by the searchBar

import UIKit

class UserPhotosViewController: BasePhotosViewController, BasePhotosViewControllerDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var pageNum = 1
    var isGettingMorePhotos: Bool = false
    var selectedPhoto: Photo?
    var savedUser: User?
    
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
        
        // I couldn't find an Interface Builder setting for this so I'm doing it programmatically here
        searchBar.autocapitalizationType = .none
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
        
        // Can't get photos without a user to get them for
        guard let user = savedUser else {
            return
        }
        
        // only show the mainActivityIndicator if there aren't any photos already shown.  Otherwise, it would cover up existing photos and look ugly.
        if dataSource.count == 0 {
            mainActivityIndicator.startAnimating()
        }
        if (shouldResetDataSource) {
            dataSource.removeAll()
            pageNum = 1
        }
        flickrApiGetPhotosFor(
            nsUserId: user.nsid,
            pageNum: pageNum,
            pageSize: PhotoDataSource.pageSize,
            failure: { nsError in
                self.mainActivityIndicator.stopAnimating()
                self.isGettingMorePhotos = false
                self.currentBatchResultCount = 0
                
                print(nsError)
                simpleAlert(vc: self, title: NSLocalizedString("Error", comment: "Alert title"), message: nsError.localizedDescription, ackStr: NSLocalizedString("OK", comment: "Alert button"))
            },
            success: { photos in
                self.mainActivityIndicator.stopAnimating()
                self.isGettingMorePhotos = false                
                self.currentBatchResultCount = photos.count
                
                if photos.count == 0 {
                    simpleAlert(vc: self, title: NSLocalizedString("No Photos", comment: "Alert title"), message: NSLocalizedString("for ", comment: "Alert message prefix. Username follows this") + "\(user.username)", ackStr: NSLocalizedString("OK", comment: "Alert button"))
                }
                self.dataSource.append(contentsOf: photos)
                
                self.collectionView.reloadData()
                self.pageNum += 1
            }
        )
    }
    
    func didSelect(photo: Photo) {
        // need to save the selected photo so it can be used in the prepare(for segue:) method to pass to the destination View Controller
        selectedPhoto = photo
        performSegue(withIdentifier: SegueId.userPhotosToPhotoCloseup, sender: nil)
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let segueId = segue.identifier else {
            print("Error, bad segue.identifier")
            return
        }
        if segueId == SegueId.userPhotosToPhotoCloseup {
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

// MARK: - UISearchBarDelegate

extension UserPhotosViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // dismiss keyboard when search has been submitted
        self.view.endEditing(true)
        
        guard let searchStr = searchBar.text else {
            simpleAlert(vc: self, title: NSLocalizedString("Error", comment: "Alert title"), message: NSLocalizedString("Please enter A Flickr username to search for", comment: "Alert message"), ackStr: NSLocalizedString("OK", comment: "Alert button"))
            return
        }
        if (searchStr.count == 0) {
            simpleAlert(vc: self, title: NSLocalizedString("Error", comment: "Alert title"), message: NSLocalizedString("Please enter A Flickr username to search for", comment: "Alert message"), ackStr: NSLocalizedString("OK", comment: "Alert button"))
            return
        }
        
        currentBatchResultCount = 0
        dataSource.removeAll()
        collectionView.reloadData()
        mainActivityIndicator.startAnimating()

        // cancel any previous requests so that they don't complete after this one is submitted but before it completes which would cause a visual glitch
        flickrApiCancelAllRequests()
        // Now that API requests are cancelled we should clear this flag so that new photos can be pulled down
        self.isGettingMorePhotos = false
        
        flickrApiFindBy(
            username: searchStr,
            failure: { nsError in
                self.mainActivityIndicator.stopAnimating()
                print(nsError)
                simpleAlert(vc: self, title: NSLocalizedString("Error", comment: "Alert title"), message: nsError.localizedDescription, ackStr: NSLocalizedString("OK", comment: "Alert button"))
                self.savedUser = nil
            },
            success : { user in
                
                // now that we have the user nsid we need to get the photos for that user
                self.savedUser = user
                self.getMorePhotos(shouldResetDataSource: true)
            }
        )
    }
}
