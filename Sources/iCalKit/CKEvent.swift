//
//  CKEvent.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation

extension CKEvent {
    
    /// Name
    public enum Name: String, CaseIterable {
        /**
         The following are REQUIRED, but MUST NOT occur more than once.
         */
        case DTSTAMP, UID
        /**
         The following is REQUIRED if the component appears in an iCalendar object that doesn't specify the "METHOD" property; otherwise, it is OPTIONAL; in any case, it MUST NOT occur more than once.
         */
        case DTSTART
        /**
         The following is OPTIONAL, but SHOULD NOT occur more than once.
         */
        case RRULE
        /**
         Either 'dtend' or 'duration' MAY appear in a 'eventprop', but 'dtend' and 'duration' MUST NOT occur in the same 'eventprop'.
         */
        case DTEND, DURATION
        /**
         The following are OPTIONAL, but MUST NOT occur more than once.
         */
        case CLASS, CREATED, DESCRIPTION, GEO, LASTMOD = "LAST-MODIFIED", LOCATION, PRIORITY, SEQ, STATUS, SUMMARY, TRANSP, URL, RECURID, ORGANIZER
        /**
         The following are OPTIONAL,  and MAY occur more than once.
         */
        case ATTACH, ATTENDEE, CATEGORIES, COMMENT, CONTACT, EXDATE, RSTATUS, RELATED, RESOURCES, RDATE
    }
}

extension CKEvent.Name: CKRegularable {
    /// String
    internal var name: String {
        return rawValue
    }
    /// mutable
    internal var mutable: Bool {
        switch self {
        case .ATTACH, .ATTENDEE, .CATEGORIES, .COMMENT, .CONTACT, .EXDATE, .RSTATUS, .RELATED, .RESOURCES, .RDATE:
            return true
        default: return false
        }
    }
    /// pattern
    internal var pattern: String {
        return #"(\r\n)\#(rawValue)([\s\S]*?)(\r\n)"#
    }
}


/// CKEvent
public class CKEvent {
    
    // MARK: - 公开属性
    
    /// [CKComponent]
    public private(set) var components: [CKComponent] = []
    /// [CKAlarm]
    public private(set) var alarms: [CKAlarm] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// 构建
    /// - Parameter contents: String
    /// - Throws: Error
    public init(from contents: String) throws {
        var contents = contents
        // 1. get alarms from string of contents
        alarms = try CKAlarm.alarms(from: &contents)
        // 2. get components from string of contents
        components = try CKComponent.components(from: &contents, withKeys: Name.allCases)
    }
    
    /// get events for contents string
    /// - Parameter contents: String
    /// - Throws: Error
    /// - Returns: [CKEvent]
    public static func events(from contents: inout String) throws -> [CKEvent] {
        let pattern: String = #"BEGIN:VEVENT([\s\S]*?)\END:VEVENT"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var events: [CKEvent] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let item = try CKEvent.init(from: content)
            events.append(item)
            contents = contents.hub.remove(with: result.range)
        }
        return events
    }
}

extension CKEvent {
    
    /// add alarm
    /// - Parameter alarms: [CKAlarm]
    @discardableResult
    public func add(alarms: [CKAlarm]) -> Self {
        return lock.hub.safe {
            self.alarms.append(contentsOf: alarms)
            return self
        }
    }
    
    /// add alarm
    /// - Parameter alarm: CKAlarm
    @discardableResult
    public func add(alarm: CKAlarm) -> Self {
        return add(alarms: [alarm])
    }
    
    /// set alarms
    /// - Parameter alarms: [CKAlarm]
    @discardableResult
    public func set(alarms: [CKAlarm]) -> Self {
        return lock.hub.safe {
            self.alarms = alarms
            return self
        }
    }
    
    /// set alarm
    /// - Parameter alarm: CKAlarm
    @discardableResult
    public func set(alarm: CKAlarm) -> Self {
        return set(alarms: [alarm])
    }
    
    /// remove all alarms
    /// - Returns: description
    @discardableResult
    public func removeAlarms() -> Self {
        return lock.hub.safe {
            self.alarms.removeAll()
            return self
        }
    }
}

// MARK: - 属性相关
extension CKEvent {
    
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
            self.components.removeAll(where:  { $0.name.uppercased() == name.rawValue.uppercased() })
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
            self.components.removeAll(where:  { $0.name.uppercased() == name.rawValue.uppercased() })
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
            self.components.removeAll(where:  { $0.name.uppercased() == name.uppercased() })
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
            self.components.removeAll(where:  { $0.name.uppercased() == name.uppercased() })
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

extension CKEvent {
    
    /// open UID
    public var openUID: String {
        guard let UID = component(for: .UID)?.value else { return "" }
        return UID.hub.md5
    }
    
    
}


// MARK: - CKTextable
extension CKEvent: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // components
        for component in components {
            contents += component.text
        }
        // alarms
        for alarm in alarms {
            contents += alarm.text
        }
        
        return "BEGIN:VEVENT\r\n" + contents + "END:VEVENT\r\n"
    }
    
    
}
