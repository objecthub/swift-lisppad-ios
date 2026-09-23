//
//  SearchPattern.swift
//  LispPad
//
//  Created by Matthias Zenger on 23/09/2026.
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

///
/// A search term together with the options that determine how it is matched against
/// text: either as a plain string (diacritic-insensitive, optionally case-insensitive),
/// or as an ICU regular expression. In regular expression mode, replacement strings are
/// templates in which `$0` refers to the whole match and `$1`, `$2`, ... refer to the
/// text captured by the corresponding groups; `\n`, `\t` and `\r` denote a newline,
/// tab and carriage return, and `\` escapes any other character (e.g. `\$`).
///
/// Empty matches (e.g. of `^` or `x*`) are skipped when searching and highlighting,
/// since they can neither be selected nor highlighted, but they are replaced by
/// `replaceAll(in:from:with:)`, following standard regular expression semantics
/// (e.g. replacing `^` with `; ` comments out every line).
///
struct SearchPattern: Equatable {
  let term: String
  let caseSensitive: Bool
  let regularExpression: Bool

  /// The compiled regular expression, if in regular expression mode and `term` is a
  /// valid regular expression; nil otherwise.
  let regex: NSRegularExpression?

  /// Matching options for regular expressions: bounds of a search range are transparent
  /// (lookbehind/lookahead see the surrounding text) and do not act as anchors (`^` only
  /// matches at actual line starts, not at the start of the search range).
  private static let matchingOptions: NSRegularExpression.MatchingOptions =
    [.withTransparentBounds, .withoutAnchoringBounds]

  init(term: String, caseSensitive: Bool, regularExpression: Bool) {
    self.term = term
    self.caseSensitive = caseSensitive
    self.regularExpression = regularExpression
    if regularExpression && !term.isEmpty {
      var options: NSRegularExpression.Options = [.anchorsMatchLines]
      if !caseSensitive {
        options.insert(.caseInsensitive)
      }
      self.regex = try? NSRegularExpression(pattern: term, options: options)
    } else {
      self.regex = nil
    }
  }

  static func == (lhs: SearchPattern, rhs: SearchPattern) -> Bool {
    return lhs.term == rhs.term &&
           lhs.caseSensitive == rhs.caseSensitive &&
           lhs.regularExpression == rhs.regularExpression
  }

  /// Returns true if `term` is a regular expression that cannot be compiled.
  var isInvalid: Bool {
    return self.regularExpression && !self.term.isEmpty && self.regex == nil
  }

  private var stringOptions: NSString.CompareOptions {
    return self.caseSensitive ? [.diacriticInsensitive] : [.diacriticInsensitive, .caseInsensitive]
  }

  /// Returns the first non-empty match within `range` of `text`, or nil if there is none.
  /// If `backwards` is set, the last match is returned instead. For regular expressions,
  /// this is the last match starting before the end of `range`; the match itself may
  /// extend beyond `range`, so that greedy matches do not get truncated.
  func find(in text: NSString, range: NSRange, backwards: Bool = false) -> NSRange? {
    guard !self.term.isEmpty else {
      return nil
    }
    if self.regularExpression {
      guard let regex = self.regex else {
        return nil
      }
      var result: NSRange? = nil
      let end = NSMaxRange(range)
      regex.enumerateMatches(in: text as String,
                             options: Self.matchingOptions,
                             range: backwards ? NSRange(location: range.location,
                                                        length: text.length - range.location)
                                              : range) { match, _, stop in
        if let match = match {
          if backwards && match.range.location >= end {
            stop.pointee = true
          } else if match.range.length > 0 {
            result = match.range
            if !backwards {
              stop.pointee = true
            }
          }
        }
      }
      return result
    } else {
      let found = text.range(of: self.term,
                             options: backwards ? self.stringOptions.union(.backwards)
                                                : self.stringOptions,
                             range: range,
                             locale: nil)
      return found.location == NSNotFound ? nil : found
    }
  }

  /// Returns the ranges of all non-empty, non-overlapping matches in `text`.
  func matchRanges(in text: NSString) -> [NSRange] {
    guard !self.term.isEmpty else {
      return []
    }
    if self.regularExpression {
      guard let regex = self.regex else {
        return []
      }
      return regex.matches(in: text as String,
                           options: Self.matchingOptions,
                           range: NSRange(location: 0, length: text.length))
        .compactMap { $0.range.length > 0 ? $0.range : nil }
    }
    var ranges: [NSRange] = []
    var searchRange = NSRange(location: 0, length: text.length)
    while searchRange.length > 0 {
      let found = text.range(of: self.term, options: self.stringOptions,
                             range: searchRange, locale: nil)
      guard found.location != NSNotFound else {
        break
      }
      ranges.append(found)
      let next = found.location + max(found.length, 1)
      guard next < text.length else {
        break
      }
      searchRange = NSRange(location: next, length: text.length - next)
    }
    return ranges
  }

  /// Returns the text with which the match at `range` in `text` is to be replaced by
  /// `replacement`. In regular expression mode, `replacement` is a template whose
  /// capture group references get expanded; if `range` is not exactly a match (e.g.
  /// because the user changed the selection), `replacement` is used literally.
  func replacement(for range: NSRange, in text: NSString, with replacement: String) -> String {
    guard self.regularExpression, let regex = self.regex else {
      return replacement
    }
    guard let match = regex.firstMatch(in: text as String,
                                       options: Self.matchingOptions.union(.anchored),
                                       range: NSRange(location: range.location,
                                                      length: text.length - range.location)),
          match.range == range else {
      return replacement
    }
    return regex.replacementString(for: match,
                                   in: text as String,
                                   offset: 0,
                                   template: Self.template(replacement))
  }

  /// Replaces all matches in `text` starting at location `start` with `replacement`
  /// (a template in regular expression mode). Returns the number of replacements.
  @discardableResult
  func replaceAll(in text: NSMutableString, from start: Int, with replacement: String) -> Int {
    guard !self.term.isEmpty else {
      return 0
    }
    let range = NSRange(location: start, length: text.length - start)
    if self.regularExpression {
      guard let regex = self.regex else {
        return 0
      }
      return regex.replaceMatches(in: text,
                                  options: Self.matchingOptions,
                                  range: range,
                                  withTemplate: Self.template(replacement))
    } else {
      return text.replaceOccurrences(of: self.term,
                                     with: replacement,
                                     options: self.stringOptions,
                                     range: range)
    }
  }

  /// Converts a user-provided replacement string into an `NSRegularExpression` template
  /// by turning `\n`, `\t` and `\r` into the corresponding control characters. All other
  /// escape sequences (e.g. `\$` and `\\`) are left for `NSRegularExpression` to handle.
  static func template(_ replacement: String) -> String {
    guard replacement.contains("\\") else {
      return replacement
    }
    var res = ""
    var escaped = false
    for ch in replacement {
      if escaped {
        switch ch {
          case "n":
            res.append("\n")
          case "t":
            res.append("\t")
          case "r":
            res.append("\r")
          default:
            res.append("\\")
            res.append(ch)
        }
        escaped = false
      } else if ch == "\\" {
        escaped = true
      } else {
        res.append(ch)
      }
    }
    if escaped {
      res.append("\\\\")
    }
    return res
  }
}
