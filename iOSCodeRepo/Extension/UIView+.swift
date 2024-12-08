//
//  UIView+.swift
//  iOSCodeRepo
//
//  Created by 丁燕军 on 2023/11/20.
//

import UIKit

extension UIView {
    
    func findInternalView<T: UIView>(clsName: String, match: (T) -> Bool,
                                     isKindOf exposedFatherType: T.Type = T.self) -> T? {
        guard let cls = NSClassFromString(clsName) else { return nil }
        return findRecursively { subview in
            match(subview) && subview.isMember(of: cls)
        }
        
    }
    
    func findRecursively<T: UIView>(match: (T) -> Bool, isKindOf type: T.Type = T.self) -> T? {
        for subview in subviews {
            if let subview = subview as? T, match(subview) {
                return subview
            } else {
                if let findView = subview.findRecursively(match: match) {
                    return findView
                }
            }
        }
        return nil
    }
    
    func printHierarchy(indent: String = "") {
        print("\(indent)\(self)")
        for subview in subviews {
            subview.printHierarchy(indent: indent + "-->>")
        }
    }
    
    func secure() {
        let selector = Selector(("setDisableUpdateMask:"))
        if layer.responds(to: selector) {
          layer.perform(selector, with: 0x12)
        }
    }

}

class SecureView: UIView {
    
    let contentView: UIView
    
    lazy var secureView: UIView =  {
//        type(of: subview).description() == "_UITextLayoutCanvasView"
        let textField = UITextField()
        textField.isSecureTextEntry = true
        guard let secureView = textField.layer.sublayers?.first?.delegate as? UIView
        else { return UIView() }
        secureView.subviews.forEach { $0.removeFromSuperview() }
        secureView.isUserInteractionEnabled = true
        return secureView
    }()
    
    init(content: UIView) {
        contentView = content
        super.init(frame: .zero)
        configure()
    }
    
    private func configure() {
        addSubview(secureView)
        secureView.addSubview(contentView)
        
        secureView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureView.trailingAnchor.constraint(equalTo: trailingAnchor),
            secureView.topAnchor.constraint(equalTo: topAnchor),
            secureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: secureView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: secureView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: secureView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: secureView.bottomAnchor)
        ])
            
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
