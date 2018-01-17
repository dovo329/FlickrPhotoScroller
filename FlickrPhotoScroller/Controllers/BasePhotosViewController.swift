//
//  BasePhotosViewController.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/12/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  The 2 main View Controllers are TopPhotosViewController and UserPhotosViewController.  They both show a scrollable and pageable grid of photos but use different API methods to get their datasources.  So much functionality is shared between them that I made a base class that they inherit the shared functionality from.  Their specific api calls and populating of the datasource are done through a protocol.  Protocols are better than implementing abstract classes in swift because protocols have compiler checking that the delegate methods are implemented and an abstract class implementation does not.  The delegate must be hooked up and be a subclass of BasePhotosViewController or else a fatalError will be thrown.

import UIKit

// class keyword limits this protocol adoption to classes only, no structs or enums allowed
protocol BasePhotosViewControllerDelegate: class {
    // delegate must be subclass of BasePhotosViewController
    
    // getMorePhotos
    // delegate has the following responsibilities:
    // Update dataSource, currentBatchResultCount
    // Show mainActivityIndicator if is first fetch i.e. dataSource.count = 0
    // Hide mainActivityIndicator when API call is finished
    // dataSource should be reset if shouldResetDataSource is true
    // reload collectionView when done
    func getMorePhotos(shouldResetDataSource: Bool)
    
    // didSelect
    // delegate has teh following responsibilities:
    // perform any function desired with selected photo such as displaying it in another view controller.
    func didSelect(photo: Photo)
}

class BasePhotosViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!    
    @IBOutlet weak var mainActivityIndicator: UIActivityIndicatorView!
    
    weak var delegate: BasePhotosViewControllerDelegate?
    
    // dataSource is updated by delegate as a result of getMorePhotos
    var dataSource = [Photo]()
    // currentBatchResultCount should be set by the subclass on the completion of getMorePhotos and is used to decide whether or not to display a loading cell
    var currentBatchResultCount = 0
    // keeps track of whether all pages have been downloaded or not to control whether we should continue to pull down more data
    var allPagesDownloaded = false
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellWithReuseIdentifier: PhotoCell.cellId)
        collectionView.register(UINib(nibName: "LoadingCell", bundle: nil), forCellWithReuseIdentifier: LoadingCell.cellId)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(BasePhotosViewController.refresh(refreshControl:)), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
    }

    override func viewDidAppear(_ animated: Bool) {
        // Detect orientation change in order to adjust the number of columns in the grid for a more consistent cell size between orientations
        NotificationCenter.default.addObserver(forName: .UIDeviceOrientationDidChange,
                                               object: nil,
                                               queue: .main,
                                               using: didRotate)
        
        // initialize the number of columns for the collectionView's flow layout
        if let flowLayout = self.collectionView.collectionViewLayout as? PhotoCollectionViewLayout {
            // The UIScreen.main.bounds.width seems to be reported correctly on app startup, so we can just use that here
            flowLayout.updateForScreen(width: UIScreen.main.bounds.width)
        }
        
        // we don't want outstanding API requests from another View Controller interfering with our current View Controller so cancel all API requests when this View Controller appears
        flickrApiCancelAllRequests()
        
        // only auto pull down more photos if there is no data to begin with. Otherwise the user would have to scroll all the way back down to the page they were on before when coming back from viewing the detail of a photo
        if (dataSource.count == 0) {
            guard let delegate = delegate else {
                fatalError("Delegate not hooked up for BasePhotosViewController")
            }
            guard delegate is BasePhotosViewController else {
                fatalError("Delegate must be subclass of BasePhotosViewController")
            }
            delegate.getMorePhotos(shouldResetDataSource: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    // had to use this notifications for orientation change instead of viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) because in viewWillTransition the collectionView was nil, even though the IBOutlet for collectionView should never be nil.
    lazy var didRotate: (Notification) -> Void = { notification in
        self.updateGridLayoutBasedOnCurrentOrientation()
    }
    
    // MARK: - Refresh Control
    @objc func refresh(refreshControl: UIRefreshControl) {
        guard let delegate = delegate else {
            fatalError("Delegate not hooked up for BasePhotosViewController")
        }
        guard delegate is BasePhotosViewController else {
            fatalError("Delegate must be subclass of BasePhotosViewController")
        }
        delegate.getMorePhotos(shouldResetDataSource: true)
        refreshControl.endRefreshing()
    }
    
    // MARK: - Utility
    func updateGridLayoutBasedOnCurrentOrientation() {
        if let flowLayout = self.collectionView.collectionViewLayout as? PhotoCollectionViewLayout {
            switch UIDevice.current.orientation {
            // The UIScreen.main.bounds.width and height may not be reported correctly in this method, but the orientation in this method is, so we'll just compute what the width really is given the orientation by taking the max or min of the reported width and height.
            case .landscapeLeft, .landscapeRight:
                flowLayout.updateForScreen(width: max(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
                self.collectionView.reloadData()
                
            case  .portrait:
                flowLayout.updateForScreen(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
                self.collectionView.reloadData()
                
            case .faceUp, .faceDown, .unknown, .portraitUpsideDown:
                break
            }
        }
    }
}

// Use extensions for datasource/delegate implementations. This is best practice according to https://clean-swift.com/refactoring-table-view-data-source-and-delegate-methods/
// MARK: - UICollectionViewDataSource

extension BasePhotosViewController : UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        // display a loading cell if there are more photos available to be downloaded
        if (dataSource.count % PhotoDataSource.pageSize == 0 && currentBatchResultCount > 0) {
            return dataSource.count + 1
        } else {
            if (dataSource.count > 0) {
                allPagesDownloaded = true
            }
            return dataSource.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row < dataSource.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.cellId, for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LoadingCell.cellId, for: indexPath)
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate

extension BasePhotosViewController : UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if indexPath.row < dataSource.count {
            if let photoCell = cell as? PhotoCell {
                // normal photo cell
                let photo = dataSource[indexPath.row]
                photoCell.configure(for: photo)
            }
        }
        // else is loading cell which needs no configuration
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // dismiss any keyboard on a photo cell select
        self.view.endEditing(true)
        
        let photo = dataSource[indexPath.row]
        guard let delegate = delegate else {
            fatalError("Delegate not hooked up for BasePhotosViewController")
        }
        guard delegate is BasePhotosViewController else {
            fatalError("Delegate must be subclass of BasePhotosViewController")
        }
        delegate.didSelect(photo: photo)
    }
}

// MARK: - UIScrollViewDelegate

extension BasePhotosViewController : UIScrollViewDelegate
{
    // detect when the scrollview has reached the bottom so we can grab more photos
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            // need this check of dataSource.coun > 0 because on startup the scrollView won't have content so it will call this even before viewDidAppear
            if (dataSource.count > 0) {
                guard let delegate = delegate else {
                    fatalError("Delegate not hooked up for BasePhotosViewController")
                }
                guard delegate is BasePhotosViewController else {
                    fatalError("Delegate must be subclass of BasePhotosViewController")
                }
                if !allPagesDownloaded {
                    delegate.getMorePhotos(shouldResetDataSource: false)
                }
            }
        }
    }
}
