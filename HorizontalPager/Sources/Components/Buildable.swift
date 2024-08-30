//
//  Buildable.swift
//  HorizontalPager
//
//  Created by Tarciziu Gologan on 30.08.2024.
//

import SwiftUI

protocol Buildable { }

extension Buildable {
    /// Mutates a property of the instance
    ///
    /// - Parameter keyPath: ``WritableKeyPath`` to the instance property to be modified
    /// - Parameter value: value to overwrite the  instance property
    func mutating<T>(keyPath: WritableKeyPath<Self, T>, value: T) -> Self {
        var newSelf = self
        newSelf[keyPath: keyPath] = value
        return newSelf
    }
}
