//
//  CollectionViewCell.swift
//  Spyfall
//
//  Created by Mike Eng on 7/1/17.
//  Copyright © 2017 Mike. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    var isClicked:Bool = true
    
    @IBOutlet weak var locationButton: UIButton!
    
    @IBAction func onClick(_ sender: Any) {
        print("locationButton clicked")
        if isClicked {
            //print("red:" + (locationButton.backgroundColor?.ciColor.red.description)!)
            //print("green:" + (locationButton.backgroundColor?.ciColor.green.description)!)
            //print("blue:" + (locationButton.backgroundColor?.ciColor.blue.description)!)
            locationButton.backgroundColor = UIColor(colorLiteralRed: 235/255, green: 123/255, blue: 45/255, alpha: 0.48)
                //colorLiteralRed: 0.922, green: 0.482, blue: 0.176, alpha: 0.48
            isClicked = false
        } else{
            locationButton.backgroundColor = UIColor(colorLiteralRed: 235/255, green: 123/255, blue: 45/255, alpha: 0.8)
                //colorLiteralRed: 0.922, green: 0.482, blue: 0.176, alpha: 0.8)
            isClicked = true
        }
    }
 
    
    func setText(text:String){
        locationButton.setTitle(text, for: .normal)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
}
