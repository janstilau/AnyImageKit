//
//  Ex+UICollectionView.swift
//  AnyImagePicker
//
//  Created by 蒋惠 on 2019/9/17.
//  Copyright © 2019 anotheren.com. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func registerCell<T: UICollectionViewCell>(_ type: T.Type) {
        let identifier = String(describing: type.self)
        register(type, forCellWithReuseIdentifier: identifier)
    }

    func dequeueReusableCell<T: UICollectionViewCell>(_ type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type.self)
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else {
            fatalError("\(type.self) was not registered")
        }
        return cell
    }
}

extension UICollectionView {
    
    func scrollToBottom(animated: Bool) {
        guard numberOfSections > 0 else { return }
        let lastSection = numberOfSections - 1
        guard numberOfItems(inSection: lastSection) > 0 else { return }
        let lastIndexPath = IndexPath(item: numberOfItems(inSection: lastSection)-1, section: lastSection)
        scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
    }
}