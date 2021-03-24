//
//  CKSerialization.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

/// CKSerialization
public class CKSerialization {
    public typealias Encoding = String.Encoding
    
    // MARK: - 生命周期
    
    /// 获取日历信息
    /// - Parameters:
    ///   - fileUrl: URL
    ///   - encoding: Encoding
    /// - Throws: Error
    /// - Returns: [CKCalendar]
    public static func calendars(with fileUrl: URL, encoding: Encoding = .utf8) throws -> [CKCalendar] {
        guard fileUrl.isFileURL == true, fileUrl.pathExtension.lowercased() == "ics" else {
            throw CKError.custom("You should put a local ics file url ... eg: xxx.ics")
        }
        let data = try Data.init(contentsOf: fileUrl)
        return try calendars(with: data, encoding: encoding)
    }
    
    /// get calendars form data
    /// - Parameters:
    ///   - data: Data
    ///   - encoding: Encoding
    /// - Throws: Error
    /// - Returns: [CKCalendar]
    public static func calendars(with data: Data, encoding: Encoding = .utf8) throws -> [CKCalendar] {
        guard let value = String.init(data: data, encoding: encoding) else {
            throw CKError.custom("Can not convert file to String ...")
        }
        return try caledars(with: value)
    }
    
    /// calendars with texdt
    /// - Parameter text: String
    /// - Throws: Error
    /// - Returns: [CKCalendar]
    public static func caledars(with text: String) throws -> [CKCalendar] {
        var value = text
        // 预处理
        while value.contains("  ") == true {
            value = value.replacingOccurrences(of: "  ", with: " ")
        }
        value = value.replacingOccurrences(of: "\r\n", with: "\n")
        value = value.replacingOccurrences(of: "\n ", with: "")
        value = value.replacingOccurrences(of: "\\n", with: "")
        value = value.replacingOccurrences(of: "\\r", with: "")
        while value.contains("\n\n") {
            value = value.replacingOccurrences(of: "\n\n", with: "\n")
        }
        value = value.replacingOccurrences(of: "\n", with: "\r\n\r\n")
        return try CKCalendar.calendars(from: &value)
    }
    
    /// data with [CKCalendar]
    /// - Parameters:
    ///   - calendars: [CKCalendar]
    ///   - ecoding: Encoding
    /// - Throws: Error
    /// - Returns: Data
    public static func data(with calendars: [CKCalendar], ecoding: Encoding = .utf8) throws -> Data {
        var contents: String = ""
        for (offset, calendar) in calendars.enumerated() {
            if offset > 0 {
                contents += "\r\n"
            }
            contents += calendar.text
        }
        guard let data = contents.data(using: ecoding) else {
            throw CKError.custom("Can not convert to data ...")
        }
        return data
    }
}
