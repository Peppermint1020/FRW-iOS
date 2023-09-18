//
//  Others.swift
//  Flow Reference Wallet
//
//  Created by Selina on 19/5/2022.
//

import Foundation
import SwiftUI

extension UICollectionReusableView {
    override open var backgroundColor: UIColor? {
        get { .clear }
        set {}
    }
}

extension Decimal {
    var doubleValue:Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
}

extension CaseIterable {
    static var count: Int {
        return Self.allCases.count
    }
}
