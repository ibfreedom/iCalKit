//
//  DateFormatter+Hub.swift
//  iCalKit
//
//  Created by tramp on 2021/3/26.
//

import Foundation

extension DateFormatter: Compatible {}
extension CompatibleWrapper where Base: DateFormatter {
    
    /// date from string
    /// - Parameters:
    ///   - string: String
    ///   - formats: [String]
    /// - Returns: Date?
    internal func date(from string: String, supports formats: [String]) -> Date? {
        for format in formats {
            base.dateFormat = format
            guard let date = base.date(from: string) else { continue }
            return date
        }
        return nil
    }
}
