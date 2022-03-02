//
//  UIViewExtensions.swift
//  collage-builder
//
//  Created by Dmytro Hrebeniuk on 5/18/19.
//  Copyright © 2019 Niklas Karlström. All rights reserved.
//

import UIKit

extension UIView {
        
    @IBInspectable open var shadowRadius: CGFloat {
        get {
            return self.layer.shadowRadius
        }
        set {
            self.layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable open var shadowOpacity: CGFloat {
        get {
            return CGFloat(self.layer.shadowOpacity)
        }
        set {
            self.layer.shadowOpacity = Float(newValue)
        }
    }
    
    @IBInspectable open var shadowOffset: CGSize {
        get {
            return self.layer.shadowOffset
        }
        set {
            self.layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable open var shadowColor: UIColor? {
        get {
            return self.layer.shadowColor.map { UIColor(cgColor: $0) }
        }
        set {
            self.layer.shadowColor = newValue?.cgColor
        }
    }
    
    @IBInspectable open var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable open var borderColor: UIColor {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable open var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable open var rotateDegress: CGFloat {
        get {
            return CGFloat(Measurement(value: Double(rotateRadians), unit: UnitAngle.radians)
                .converted(to: .radians).value)
        }
        set {
            rotateRadians = CGFloat(Measurement(value: Double(newValue), unit: UnitAngle.degrees)
                .converted(to: .radians).value)
        }
    }
    
    open var rotateRadians: CGFloat {
        get {
            return atan2(transform.b, transform.a)
        }
        set {
            transform = CGAffineTransform(rotationAngle: newValue)
        }
    }
    
    func insertIntoContainer(view subview: UIView, leftInset: CGFloat = 0.0, rightInset: CGFloat = 0.0, verticalInset: CGFloat = 0.0, height: CGFloat? = nil) {
        insertIntoContainer(view: subview, leftInset: leftInset, rightInset: rightInset, topInset: verticalInset, bottomInset: verticalInset, height: height)
    }
    
    func insertIntoContainer(view subview: UIView, leftInset: CGFloat = 0.0, rightInset: CGFloat = 0.0, topInset: CGFloat = 0.0, bottomInset: CGFloat = 0.0, height: CGFloat? = nil) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(subview)
        
        height.map { subview.heightAnchor.constraint(equalToConstant: $0) }?.isActive = true
        
        subview.topAnchor.constraint(equalTo: topAnchor, constant: topInset).isActive = true
        let bottomConstraint = subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomInset)
        bottomConstraint.isActive = true

        subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leftInset).isActive = true
        subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -rightInset).isActive = true
    }
    
}
