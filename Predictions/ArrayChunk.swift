//
//  ArrayExt.swift
//  Grid Demo
//
//  Created by Jakub Charvat on 07/04/2020.
//  Adapted by Jakub Charvat from © 2019 Paul Hudson, https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks. All rights reseved
//

import Foundation

extension Array {
    /// Break the array into a 2D array of subarrays of `size`
    ///
    /// Example:
    /// ```swift
    /// let arr = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    ///
    /// arr.chunked(into: 2) // [[0, 1], [2, 3], [4, 5], [6, 7], [8]]
    /// arr.chunked(into: 3) // [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
    /// ```
    ///
    /// - Parameter size: The size of the arrays this array should be broken into
    /// - Returns: A 2-dimensional representation of the original array broken into smaller arrays of `size`
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
