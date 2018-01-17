//
//  PhotoCollectionViewLayout.swift
//  JanePhotoScroller
//
//  Created by Douglas Voss on 1/13/18.
//  Copyright © 2018 VossWareLLC. All rights reserved.
//
//  Simple grid layout with programmable numberOfColumns.  Sets 1.0 point for spacing between items.

import Foundation
import UIKit

class PhotoCollectionViewLayout : UICollectionViewFlowLayout {
    
    var numberOfColumns : Int = 3

    override init() {
        super.init()
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    func setupLayout() {
        minimumInteritemSpacing = 0.0
        minimumLineSpacing = 1.0
        scrollDirection = .vertical
    }
    
    override var itemSize: CGSize {
        set {

        }
        get {
            guard let collectionView = self.collectionView else {
                print("Error getting collectionView in PhotoCollectionViewLayout")
                return CGSize(width: 0.0, height: 0.0)
            }
            let itemWidth = ((collectionView.bounds.size.width) - (CGFloat(numberOfColumns - 1)*(1.0))) / CGFloat(numberOfColumns)
            let itemHeight = itemWidth
            return CGSize(width: itemWidth, height: itemHeight)
        }
    }
    
    func updateForScreen(width: CGFloat) {
        numberOfColumns = Int(floor(width / 100.0))
    }
}
