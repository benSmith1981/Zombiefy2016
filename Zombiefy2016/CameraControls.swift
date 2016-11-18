//
//  CameraControls.swift
//  Zombiefy2016
//
//  Created by Ben Smith on 16/11/2016.
//  Copyright © 2016 Ben Smith. All rights reserved.
//

import UIKit

@objc class CameraControls: UIView {

    @objc public var delegate: CameraControlsProtocol?
    @objc public var number: Int = 1

    @IBAction func record(_ sender: AnyObject) {
        delegate?.record()
    }
    
    @IBAction func switchCamera(_ sender: AnyObject) {
        delegate?.switchCamera()
    }


}
