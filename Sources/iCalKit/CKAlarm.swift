//
//  CKAlarm.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation


extension CKAlarm {
    
    /// Name refer: https://tools.ietf.org/html/rfc5545#section-3.4
    public enum Name: String, CaseIterable {
        /**
         MUST NOT occur more than once.
         */
        case ACTION, TRIGGER, DESCRIPTION, SUMMARY
        /**
         'duration' and 'repeat' are both OPTIONAL, and MUST NOT occur more than once each; but if one occurs, so MUST the other.
         */
        case DURATION, REPEAT
        /**
         The following is OPTIONAL,  but MUST NOT occur more than once.
         */
        case ATTACH
        /**
         The following is OPTIONAL,  and MAY occur more than once. X-PROP / IANA-PROP
         */
        case ATTENDEE
    }
    
}

extension CKAlarm.Name: CKRegularable {
    /// String
    internal var name: String {
        return rawValue
    }
    /// mutable
    internal var mutable: Bool {
        let mutables: [CKAlarm.Name] = [.ATTENDEE]
        return mutables.contains(self)
    }
    /// pattern
    internal var pattern: String {
        return #"(\r\n)\#(rawValue)([\s\S]*?)(\r\n)"#
    }
}

/// CKAlarm
public class CKAlarm {
    
    // MARK: - 公开属性
    
    /// [CKComponent]
    public private(set) var components: [CKComponent] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// create alarm from string
    /// - Parameter contents: String
    /// - Throws: throws
    public init(from contents: String) throws {
        var contents = contents
        // 1. get attrs
        components = try CKComponent.components(from: &contents, withKeys: Name.allCases)
    }
    
    
    /// get alarms from string of contents
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKAlarm]
    public static func alarms(from contents: inout String) throws -> [CKAlarm] {
        let pattern: String = #"BEGIN:VALARM([\s\S]*?)END:VALARM"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var alarms: [CKAlarm] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let item = try CKAlarm.init(from: content)
            alarms.append(item)
            contents = contents.hub.remove(with: result.range)
        }
        return alarms
    }
}

// MARK: - 更新/获取属性
extension CKAlarm {
    
    /// components for name
    /// - Parameter name: Name
    /// - Returns: [CKComponent]
    public func components(for name: Name) -> [CKComponent] {
        return lock.hub.safe { [unowned self] in
            return self.components.filter { $0.name.uppercased() == name.rawValue.uppercased() }
        }
    }
    
    /// component for name
    /// - Parameter name: Name
    /// - Returns: CKComponent?
    public func component(for name: Name) -> CKComponent? {
        return components(for: name).first
    }
    
    /// components for name
    /// - Parameter name: String
    /// - Returns: [CKComponent]
    public func components(for name: String) -> [CKComponent] {
        return lock.hub.safe {
            return self.components.filter { $0.name.uppercased() == name.uppercased() }
        }
    }
    
    /// component for name
    /// - Parameter name: String
    /// - Returns: CKComponent?
    public func component(for name: String) -> CKComponent? {
        return components(for: name).first
    }
    
    /// add components [CKComponent]
    /// - Parameters:
    ///   - components: [CKComponent]
    ///   - name: Name
    @discardableResult
    public func add(_ components: [CKComponent], for name: Name) -> Self {
        if let index = self.components.lastIndex(where: { $0.name.uppercased() == name.rawValue.uppercased() }) {
           return lock.hub.safe {
                if name.mutable == true {
                    self.components.insert(contentsOf: components, at: index + 1)
                } else {
                    guard let item = components.first else { return self }
                    self.components[index] = item
                }
                return self
            }
        } else {
           return lock.hub.safe {
                if name.mutable == true {
                    self.components.append(contentsOf: components)
                } else {
                    guard let item = components.first else { return self }
                    self.components.append(item)
                }
                return self
            }
        }
    }
    
    /// add component for name
    /// - Parameters:
    ///   - component: CKComponent
    ///   - name: Name
    @discardableResult
    public func add(_ component: CKComponent, for name: Name) -> Self {
       return add([component], for: name)
    }
    
    /// add components [CKComponent]
    /// - Parameters:
    ///   - components: [CKComponent]
    ///   - name: String
    @discardableResult
    public func add(_ components: [CKComponent], for name: String) -> Self {
        if let index = self.components.lastIndex(where: { $0.name.uppercased() == name.uppercased() }) {
            return lock.hub.safe {
                if name.uppercased().hub.hasPrefix(["X-","IANA-"]) == true {
                    self.components.insert(contentsOf: components, at: index + 1)
                } else {
                    guard let item = components.first else { return self }
                    self.components[index] = item
                }
                return self
            }
        } else {
            return lock.hub.safe {
                if name.uppercased().hub.hasPrefix(["X-","IANA-"]) == true {
                    self.components.append(contentsOf: components)
                } else {
                    guard let item = components.first else { return self }
                    self.components.append(item)
                }
                return self
            }
        }
    }
    
    /// add component for name
    /// - Parameters:
    ///   - component: CKComponent
    ///   - name: String
    @discardableResult
    public func add(_ component: CKComponent, for name: String) -> Self {
       return add([component], for: name)
    }
    
    /// set components for name
    /// - Parameters:
    ///   - components: [CKComponent]
    ///   - name: Name
    /// - Returns: Self
    @discardableResult
    public func set(_ components: [CKComponent], for name: Name) -> Self {
        if let index = self.components.firstIndex(where: { $0.name.uppercased() == name.rawValue.uppercased() }) {
            self.components.removeAll(keepingCapacity: true)
            return lock.hub.safe {
                if name.mutable == true {
                    self.components.insert(contentsOf: components, at: index)
                } else {
                    guard let item = components.first else { return self }
                    self.components[index] = item
                }
                return self
            }
        } else {
            self.components.removeAll(keepingCapacity: true)
            return lock.hub.safe {
                if name.mutable == true {
                    self.components.append(contentsOf: components)
                } else {
                    guard let item = components.first else { return self }
                    self.components.append(item)
                }
                return self
            }
        }
    }
    
    /// set component for name
    /// - Parameters:
    ///   - component: CKComponent
    ///   - name: Name
    /// - Returns: Self
    @discardableResult
    public func set(_ component: CKComponent, for name: Name) -> Self {
        return set([component], for: name)
    }
    
    /// set components for name
    /// - Parameters:
    ///   - components: [CKComponent]
    ///   - name: String
    /// - Returns: Self
    @discardableResult
    public func set(_ components: [CKComponent], for name: String) -> Self {
        if let index = self.components.firstIndex(where: { $0.name.uppercased() == name.uppercased() }) {
            self.components.removeAll(keepingCapacity: true)
            return lock.hub.safe {
                if name.uppercased().hub.hasPrefix(["X-","IANA-"]) == true {
                    self.components.insert(contentsOf: components, at: index)
                } else {
                    guard let item = components.first else { return self }
                    self.components[index] = item
                }
                return self
            }
        } else {
            self.components.removeAll(keepingCapacity: true)
            return lock.hub.safe {
                if name.uppercased().hub.hasPrefix(["X-","IANA-"]) == true {
                    self.components.append(contentsOf: components)
                } else {
                    guard let item = components.first else { return self }
                    self.components.append(item)
                }
                return self
            }
        }
    }
    
    /// set component for name
    /// - Parameters:
    ///   - component: CKComponent
    ///   - name: String
    /// - Returns: Self
    @discardableResult
    public func set(_ component: CKComponent, for name: String) -> Self {
        return set([component], for: name)
    }
}

// MARK: - CKTextable
extension CKAlarm: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // components
        for component in components {
            contents += component.text
        }
        return "BEGIN:VALARM\r\n" + contents + "END:VALARM\r\n"
    }
    
}
