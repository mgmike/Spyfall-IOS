//
//  FriendCollectionViewFlowLayout.swift
//  Spyfall
//
//  Created by Mike Eng on 7/19/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit

class FriendCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }
    
    override var itemSize: CGSize{
        set{}
        get{
            let itemWidth = self.collectionView!.frame.width
            return CGSize(width: itemWidth, height: (itemWidth) / 4)
        }
    }
    
    func setupLayout(){
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        scrollDirection = .vertical
    }
}
