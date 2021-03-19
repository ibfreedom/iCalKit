//
//  CKCalendar.swift
//  iCalendarKit
//
//  Created by tramp on 2021/3/3.
//

import Foundation


extension CKCalendar {
    /// Name
    public enum Name: String, CaseIterable {
        /**
         The following are REQUIRED, but MUST NOT occur more than once.
         */
        case PRODID, VERSION
        /**
         The following are OPTIONAL, but MUST NOT occur more than once.
         */
        case CALSCALE, METHOD
    }
}

extension CKCalendar.Name: CKRegularable {
    /// String
    internal var name: String {
        return rawValue
    }
    /// is mutable
    internal var mutable: Bool {
        false
    }
    /// pattern
    internal var pattern: String {
        return #"(\r\n)\#(rawValue)([\s\S]*?)(\r\n)"#
    }
}

/// CKCalendar
public class CKCalendar {
    
    // MARK: - 公开属性
    
    /// [CKEvent]
    public private(set) var events: [CKEvent] = []
    /// [CKJournal]
    public private(set) var journals: [CKJournal] = []
    /// [CKTodo]
    public private(set) var todos: [CKTodo] = []
    /// [CKFreeBusy]
    public private(set) var freebusys: [CKFreeBusy] = []
    /// [CKTimezone]
    public private(set) var timezones: [CKTimezone] = []
    /// [CKAlarm]
    public private(set) var alarms: [CKAlarm] = []
    /// [CKComponent]
    public private(set) var components: [CKComponent] = []
    
    // MARK: - 私有属性
    
    /// NSLock
    private lazy var lock: NSLock = .init()
    
    // MARK: - 生命周期
    
    /// 构建
    /// - Parameter contents: String
    /// - Throws: throws
    public init(with contents: String) throws {
        var contents = contents
        // 解析 VEVENT
        events = try CKEvent.events(from: &contents)
        // 时区信息
        timezones = try CKTimezone.timezones(from: &contents)
        // journal
        journals = try CKJournal.journals(from: &contents)
        // freebusy
        freebusys = try CKFreeBusy.freebusys(from: &contents)
        /// alarms
        alarms = try CKAlarm.alarms(from: &contents)
        // todo
        todos = try CKTodo.todos(from: &contents)
        // components
        components = try CKComponent.components(from: &contents, withKeys: Name.allCases)

    }
    
    /// get CKCalendar Array
    /// - Throws: Error
    /// - Returns: [CKCalendar]
    public static func calendars(from contents: inout String) throws -> [CKCalendar] {
        let pattern: String = #"BEGIN:VCALENDAR([\s\S]*?)END:VCALENDAR"#
        let reg = try NSRegularExpression.init(pattern: pattern, options: [.caseInsensitive])
        let results = reg.matches(in: contents, options: [], range: contents.hub.range).sorted(by: { $0.range.location > $1.range.location })
        var calendars: [CKCalendar] = []
        for result in results {
            let content = contents.hub.substring(with: result.range)
            let calendar = try CKCalendar.init(with: content)
            calendars.append(calendar)
            contents = contents.hub.remove(with: result.range)
        }
        return calendars
    }
}

// MARK: -  event
extension CKCalendar {
    
    /// add events
    /// - Parameter events: [CKEvent]
    @discardableResult
    public func add(events: [CKEvent]) -> Self {
        return lock.hub.safe {
            self.events.append(contentsOf: events)
            return self
        }
    }
    
    /// add event
    /// - Parameter event: CKEvent
    @discardableResult
    public func add(event: CKEvent) -> Self {
        return add(events: [event])
    }
    
    /// set events
    /// - Parameter events: [CKEvent]
    @discardableResult
    public func set(events: [CKEvent]) -> Self {
        return lock.hub.safe {
            self.events = events
            return self
        }
    }
    
    /// set event
    /// - Parameter event: CKEvent
    @discardableResult
    public func set(event: CKEvent) -> Self {
        return set(events: [event])
    }
    
    /// event for uid
    /// - Parameter UID: String
    /// - Returns: CKEvent?
    public func event(for UID: String) -> CKEvent? {
        return lock.hub.safe {
            return events.first(where:  { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all events with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeEvents(with UID: String) -> Self {
        return lock.hub.safe {
            self.events.removeAll(where: { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all events
    /// - Returns: description
    @discardableResult
    public func removeEvents() -> Self {
        return lock.hub.safe {
            self.events.removeAll()
            return self
        }
    }
}

// MARK: - timezones
extension CKCalendar {
    
    /// add timezones
    /// - Parameter timezones: [CKTimezone]
    @discardableResult
    public func add(timezones: [CKTimezone]) -> Self {
        return lock.hub.safe {
            self.timezones.append(contentsOf: timezones)
            return self
        }
    }
    
    /// add timezone
    /// - Parameter timezone: CKTimezone
    @discardableResult
    public func add(timezone: CKTimezone) -> Self {
        return add(timezones: [timezone])
    }
    
    /// set timezones
    /// - Parameter timezones: [CKTimezone]
    @discardableResult
    public func set(timezones: [CKTimezone]) -> Self {
        return lock.hub.safe {
            self.timezones = timezones
            return self
        }
    }
    
    /// set timezone
    /// - Parameter timezone: CKTimezone
    @discardableResult
    public func set(timezone: CKTimezone) -> Self {
        return set(timezones: [timezone])
    }
    
    /// timezone for uid
    /// - Parameter TZID: String
    /// - Returns: CKTimezone?
    public func timezone(for TZID: String) -> CKTimezone? {
        return lock.hub.safe {
            return timezones.first(where:  { $0.component(for: .TZID)?.value.uppercased() == TZID.uppercased() })
        }
    }
    
    /// remove all timezones with TZID
    /// - Parameter TZID: String
    @discardableResult
    public func removeTimezones(with TZID: String) -> Self {
        return lock.hub.safe {
            self.timezones.removeAll(where: { $0.component(for: .TZID)?.value.uppercased() == TZID.uppercased() })
            return self
        }
    }
    
    /// remove all Timezones
    /// - Returns: description
    @discardableResult
    public func removeTimezones() -> Self {
        return lock.hub.safe {
            self.timezones.removeAll()
            return self
        }
    }
}

// MARK: - journals
extension CKCalendar {
    
    /// add journal
    /// - Parameter journals: [CKJournal]
    @discardableResult
    public func add(journals: [CKJournal]) -> Self {
        return lock.hub.safe {
            self.journals.append(contentsOf: journals)
            return self
        }
    }
    
    /// add journal
    /// - Parameter journal: CKJournal
    @discardableResult
    public func add(journal: CKJournal) -> Self {
        return add(journals: [journal])
    }
    
    /// set journals
    /// - Parameter journals: [CKJournal]
    @discardableResult
    public func set(journals: [CKJournal]) -> Self {
        return lock.hub.safe {
            self.journals = journals
            return self
        }
    }
    
    /// set journal
    /// - Parameter journal: CKJournal
    @discardableResult
    public func set(journal: CKJournal) -> Self {
        return set(journals: [journal])
    }
    
    /// journal for uid
    /// - Parameter UID: String
    /// - Returns: CKJournal?
    public func journal(for UID: String) -> CKJournal? {
        return lock.hub.safe {
            return journals.first(where:  { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all journals with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeJournals(with UID: String) -> Self {
        return lock.hub.safe {
            self.journals.removeAll(where: { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all journals
    /// - Returns: description
    @discardableResult
    public func removeJournals() -> Self {
        return lock.hub.safe {
            self.journals.removeAll()
            return self
        }
    }
}

// MARK: - freebusys
extension CKCalendar {
    
    /// add freebusy
    /// - Parameter freebusys: [CKFreeBusy]
    @discardableResult
    public func add(freebusys: [CKFreeBusy]) -> Self {
        return lock.hub.safe {
            self.freebusys.append(contentsOf: freebusys)
            return self
        }
    }
    
    /// add freebusy
    /// - Parameter freebusy: CKFreeBusy
    @discardableResult
    public func add(freebusy: CKFreeBusy) -> Self {
        return add(freebusys: [freebusy])
    }
    
    /// set freebusys
    /// - Parameter freebusys: [CKFreeBusy]
    @discardableResult
    public func set(freebusys: [CKFreeBusy]) -> Self {
        return lock.hub.safe {
            self.freebusys = freebusys
            return self
        }
    }
    
    /// set freebusy
    /// - Parameter freebusy: CKFreeBusy
    @discardableResult
    public func set(freebusy: CKFreeBusy) -> Self {
        return set(freebusys: [freebusy])
    }
    
    /// freebusy for uid
    /// - Parameter UID: String
    /// - Returns: CKFreeBusy?
    public func freebusy(for UID: String) -> CKFreeBusy? {
        return lock.hub.safe {
            return freebusys.first(where:  { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all freebusys with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeFreebusys(with UID: String) -> Self {
        return lock.hub.safe {
            self.freebusys.removeAll(where: { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all freebusys
    /// - Returns: description
    @discardableResult
    public func removeFreebusys() -> Self {
        return lock.hub.safe {
            self.freebusys.removeAll()
            return self
        }
    }
}

// MARK: - alarms
extension CKCalendar {
    
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

// MARK: - todo
extension CKCalendar {
    
    
    /// add todos
    /// - Parameter todos: [CKTodo]
    @discardableResult
    public func add(todos: [CKTodo]) -> Self {
        return lock.hub.safe {
            self.todos.append(contentsOf: todos)
            return self
        }
    }
    
    /// add todo
    /// - Parameter todo: CKTodo
    @discardableResult
    public func add(todo: CKTodo) -> Self {
        return add(todos: [todo])
    }
    
    /// set todos
    /// - Parameter todos: [CKTodo]
    @discardableResult
    public func set(todos: [CKTodo]) -> Self {
        return lock.hub.safe {
            self.todos = todos
            return self
        }
    }
    
    /// set todo
    /// - Parameter todo: CKFreeBusy
    @discardableResult
    public func set(todo: CKTodo) -> Self {
        return set(todos: [todo])
    }
    
    /// todo for uid
    /// - Parameter UID: String
    /// - Returns: CKFreeBusy?
    public func todo(for UID: String) -> CKTodo? {
        return lock.hub.safe {
            return todos.first(where:  { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
        }
    }
    
    /// remove all todos with uid
    /// - Parameter UID: String
    @discardableResult
    public func removeTodos(with UID: String) -> Self {
        return lock.hub.safe {
            self.todos.removeAll(where: { $0.component(for: .UID)?.value.uppercased() == UID.uppercased() })
            return self
        }
    }
    
    /// remove all todos
    /// - Returns: description
    @discardableResult
    public func removeTodos() -> Self {
        return lock.hub.safe {
            self.todos.removeAll()
            return self
        }
    }
}

// MARK: - 属性相关
extension CKCalendar {
    
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

// MARK: - CKTextable
extension CKCalendar: CKTextable {
    
    /// ics format string
    public var text: String {
        var contents: String = ""
        // attrs
        for item in components {
            contents += item.text
        }
        // timezones
        for item in timezones {
            contents += item.text
        }
        // events
        for item in events {
            contents += item.text
        }
        // todos
        for item in todos {
            contents += item.text
        }
        // journals
        for item in journals {
            contents += item.text
        }
        // freebusys
        for item in freebusys {
            contents += item.text
        }
        
        return "BEGIN:VCALENDAR\r\n" + contents + "END:VCALENDAR"
    }
    
    
}
