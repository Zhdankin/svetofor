//
//  UIViewControllerExtentions.swift
//  iOSPhotoFilters
//
//  Created by Dmytro Hrebeniuk on 2/3/18.
//  Copyright © 2018 Dmytro Hrebeniuk. All rights reserved.
//

import UIKit

extension UIViewController {
	
	func insert(viewController: UIViewController, into superView: UIView) {
		self.addChildViewController(viewController)
        superView.insertIntoContainer(view: viewController.view)
	}
	
}
