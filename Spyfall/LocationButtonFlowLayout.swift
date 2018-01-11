//
//  LocationButtonFlowLayout.swift
//  Spyfall
//
//  Created by Mike Eng on 7/2/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit

class LocationButtonFlowLayout: UICollectionViewFlowLayout {
    
    
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
            let itemWidth = (self.collectionView!.frame.width * 7) / 16
            return CGSize(width: itemWidth, height: (itemWidth) / 2)
        }
    }
    
    func setupLayout(){
        minimumLineSpacing = 2
        minimumInteritemSpacing = 2
        scrollDirection = .vertical
    }

}
