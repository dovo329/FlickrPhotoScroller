//
//  PhotoCell.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/13/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  There is some business logic in this view but it is minimal.  The business logic is just starting and stopping network requests to get the image.  This is technically a View Model and View combined.

import Foundation
import UIKit
import AlamofireImage

protocol PhotoCellDelegate: class {
    func photoUrlDownload(error: Error, indexPath: IndexPath)
}

class PhotoCell: UICollectionViewCell {
    
    // Use this for the reuse identifier for the collectionView
    static let cellId = "PhotoCellId"
    weak var delegate: PhotoCellDelegate?
    var indexPath: IndexPath?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // configure should called when the cell will be displayed
    func configure(for photo: Photo, delegate: PhotoCellDelegate, indexPath: IndexPath) {
        do {
            self.delegate = delegate
            self.indexPath = indexPath
            
            let photoUrl = try flickrApiUrlForThumbnail(photo: photo)
                                    
            activityIndicator.startAnimating()
            imageView.af_setImage(
                withURL: photoUrl,
                completion: { response in
                    if let error = response.error {
                        guard let delegate = self.delegate else {
                            fatalError("Delegate not hooked up for PhotoCell")
                        }
                        guard let indexPath = self.indexPath else {
                            fatalError("indexPath not set for PhotoCell")
                        }

                        if let afiError = error as? AlamofireImage.AFIError {
                            if afiError != .requestCancelled {
                                delegate.photoUrlDownload(error: error, indexPath: indexPath)
                            }
                        } else {
                            let nsError = error as NSError
                            if nsError.code != NSURLErrorCancelled {
                                delegate.photoUrlDownload(error: error, indexPath: indexPath)
                            }
                        }
                    }
                }
            )

        } catch {
            let nsError = error as NSError
            print(nsError)
        }
    }
    
    // this is called when the cell has been recycled and is going to be resused.  We should cancel network requests so that we're not trying to download an image for a previous cell.  We should also clear the image.
    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel the image network request if the cell is going to be reused.  This may be the case when the image download started but the cell was scroll off the screen before it finished
        imageView.af_cancelImageRequest()
        imageView.image = nil
    }
}
