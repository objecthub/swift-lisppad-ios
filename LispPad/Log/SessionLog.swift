//
//  SessionLog.swift
//  LispPad
//
//  Created by Matthias Zenger on 23/10/2021.
//  Copyright © 2021 Matthias Zenger. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

final class SessionLog: ObservableObject {
  
  /// The session log singleton object
  static let standard = SessionLog()
  
  /// Maximum number of log entries
  private var maxLogEntries: Int
  
  /// Filters
  private(set) var severityFilter: Severity
  private(set) var tagFilter: Bool
  private(set) var messageFilter: Bool
  private(set) var searchString: String
  private(set) var excludeSearch: Bool
  
  /// The log entries
  private var logEntries: [LogEntry] = []
  
  /// Filtered log entry indices
  var filteredLogEntries: [LogEntry] = []
  
  /// Synchronization
  private var mutex = NSLock()
  
  /// State identifier (to be used by clients to determine if a state change has occured since
  /// last looking at the session log)
  @Published var stateId: UInt64 = 0
  
  /// Prevent creation of SessionLog entries from outside the class; make this a singleton
  /// object and pull in all the default values from the settings object.
  private init() {
    self.maxLogEntries = UserSettings.standard.logMaxHistory
    self.severityFilter = UserSettings.standard.logSeverityFilter
    self.searchString = SessionLog.normalizeSearchString(UserSettings.standard.logMessageFilter)
    self.messageFilter = UserSettings.standard.logFilterMessages
    self.tagFilter = UserSettings.standard.logFilterTags
    self.excludeSearch = UserSettings.standard.logMessageFilter
                           .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                           .starts(with: "-")
  }
  
  private func stateUpdated() {
    DispatchQueue.main.async {
      self.stateId &+= 1
    }
  }
  
  private static func normalizeSearchString(_ str: String) -> String {
    let res = str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    if res.starts(with: "-") || res.starts(with: "\\") {
      return String(res.suffix(from: res.index(res.startIndex, offsetBy: 1)))
    } else {
      return res
    }
  }
  
  func setMaxLogEntries(_ maxEntries: Int) {
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    self.maxLogEntries = maxEntries
    self.filterLogEntries()
  }
  
  func set(severity: Severity, search: String, tag: Bool, message: Bool) {
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    self.severityFilter = severity
    self.searchString = SessionLog.normalizeSearchString(search)
    self.tagFilter = tag
    self.messageFilter = message
    self.excludeSearch = search
                           .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                           .starts(with: "-")
    self.filterLogEntries()
  }
  
  private func matchesFilter(_ logEntry: LogEntry) -> Bool {
    if logEntry.severity.rawValue < self.severityFilter.rawValue {
      return false
    }
    let searchString = self.searchString
    if !searchString.isEmpty {
      let res: Bool
      if self.tagFilter && self.messageFilter {
        res = logEntry.tag.hasPrefix(searchString) || logEntry.message.contains(searchString)
      } else if self.tagFilter {
        res = logEntry.tag.hasPrefix(searchString)
      } else if self.messageFilter {
        res = logEntry.message.contains(searchString)
      } else {
        res = true
      }
      if self.excludeSearch {
        return !res
      } else {
        return res
      }
    }
    return true
  }
  
  func reapplyFilter() {
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    self.filterLogEntries()
  }
  
  private func filterLogEntries() {
    self.filteredLogEntries.removeAll()
    for logEntry in self.logEntries {
      if self.matchesFilter(logEntry) {
        self.filteredLogEntries.append(logEntry)
      }
    }
    self.stateUpdated()
  }

  var filteredLogEntryCount: Int {
    return self.filteredLogEntries.count
  }
  
  func filteredLogEntry(at index: Int) -> LogEntry? {
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    guard index >= 0 && index < self.filteredLogEntries.count else {
      return nil
    }
    return self.filteredLogEntries[index]
  }
  
  func addLogEntry(time: Double? = nil,
                   severity: Severity,
                   tag: String,
                   message: String) {
    let logEntry = LogEntry(time: time,
                            severity: severity,
                            tag: tag,
                            message: message)
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    self.logEntries.append(logEntry)
    if self.matchesFilter(logEntry) {
      self.filteredLogEntries.append(logEntry)
    }
    if self.logEntries.count > self.maxLogEntries {
      let numToRemove = self.logEntries.count - self.maxLogEntries
      var numFilteredToRemove = 0
      for i in 0..<numToRemove {
        let logEntry = self.logEntries[i]
        if numFilteredToRemove < self.filteredLogEntries.count &&
           self.filteredLogEntries[numFilteredToRemove] === logEntry {
          numFilteredToRemove += 1
        }
      }
      self.filteredLogEntries.removeFirst(numFilteredToRemove)
      self.logEntries.removeFirst(numToRemove)
    }
    self.stateUpdated()
  }
  
  func clear(all: Bool = true) {
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    self.filteredLogEntries.removeAll()
    guard !all else {
      self.logEntries.removeAll()
      self.stateUpdated()
      return
    }
    self.logEntries.removeAll(where: { logEntry in self.matchesFilter(logEntry) })
    self.stateUpdated()
  }
  
  func export(withHeader header: Bool = true) -> String {
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    var logfile = header ? "\"Date\",\"Session\",\"Severity\",\"Tag\",\"Message\"\n" : ""
    for logEntry in self.logEntries {
      logfile += logEntry.csvEncoded + "\n"
    }
    return logfile
  }
  
  func exportMessages() -> String {
    self.mutex.lock()
    defer {
      self.mutex.unlock()
    }
    var logfile = ""
    for logEntry in self.logEntries {
      logfile += logEntry.message + "\n"
    }
    return logfile
  }
}

final class LogEntry {
  let id = UUID()
  let time: Date
  let severity: Severity
  let tag: String
  let message: String
  let messageLines: Int
  
  static let timeFormatter: DateFormatter = {
    var df = DateFormatter()
    df.dateFormat = "HH:mm:ss"
    return df
  }()
  
  static let dateFormatter: DateFormatter = {
    var df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd\nHH:mm:ss"
    return df
  }()
  
  static let csvDateFormatter: DateFormatter = {
    var df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return df
  }()
  
  init(time: Double?, severity: Severity, tag: String, message: String) {
    self.time = time == nil ? Date() : Date(timeIntervalSince1970: time!)
    self.severity = severity
    self.tag = tag
    self.message = message
    var numberOfLines = 0
    var index = 0
    let str = message as NSString
    while index < str.length {
      index = NSMaxRange(str.lineRange(for: NSMakeRange(index, 0)))
      numberOfLines += 1
    }
    self.messageLines = numberOfLines
  }
  
  var timeString: String {
    LogEntry.timeFormatter.string(from: self.time)
  }
  
  var dateTimeString: String {
    LogEntry.dateFormatter.string(from: self.time)
  }
  
  var csvEncoded: String {
    "\"\(LogEntry.csvDateFormatter.string(from: self.time))\"," +
    "\"\(self.severity.description)\"," +
    "\"\(self.tag.replacingOccurrences(of: "\"", with: "\"\""))\"," +
    "\"\(self.message.replacingOccurrences(of: "\"", with: "\"\""))\""
  }
}

enum Severity: UInt8, CustomStringConvertible {
  case debug
  case info
  case warning
  case error
  case fatal
  
  init(_ str: String) {
    switch str {
      case "Info":
        self = .info
      case "Warning":
        self = .warning
      case "Error":
        self = .error
      case "Fatal":
        self = .fatal
      default:
        self = .debug
    }
  }
  
  var description: String {
    switch self {
      case .debug:
        return "Debug"
      case .info:
        return "Info"
      case .warning:
        return "Warning"
      case .error:
        return "Error"
      case .fatal:
        return "Fatal"
    }
  }
}
