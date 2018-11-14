// Copyright © 2016 Slant.
//
// This file is part of MO. The full MO copyright notice, including terms
// governing use, modification, and redistribution, is contained in the file
// LICENSE at the root of the source code distribution tree.

import Foundation

extension Data {
    /// Extracts a specific type from raw data.
    ///
    /// - Parameters:
    ///   - type: the stored type
    ///   - offset: the offset in bytes
    /// - Returns: the stored valye
    public func extract<T>(_ type: T.Type, at offset: Int) -> T {
        return self.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) -> T in
            pointer.advanced(by: offset).withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
    }

    /// Appends a specific value as raw data.
    ///
    /// - Parameter value: the value to append
    public mutating func append<T>(_ value: T) {
        var varValue = value
        withUnsafePointer(to: &varValue) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                append($0, count: MemoryLayout<T>.size)
            }
        }
    }
}
