//
//  GetResultValue.swift
//  LispPad
//
//  Created by Matthias Zenger on 18/04/2026.
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

import AppIntents
import Foundation
import LispKit

struct GetResultValue: AppIntent {
  
  /// The title of the intent
  static var title: LocalizedStringResource = "Get Result Value"
  
  /// The description of the intent
  static var description = IntentDescription("Returns the n-th result value of a program execution run.")
  
  @Parameter(title: "Result", description: "The result of a program evaluation run.")
  var result: EvalResult
  
  @Parameter(title: "Index",
             description: "The index of the result value.",
             controlStyle: .stepper,
             inclusiveRange: (lowerBound: 0, upperBound: 9))
  var index: Int
  
  @Parameter(title: "Default",
             description: "A default in case the result does not have a value at the given index.",
             inputConnectionBehavior: .never)
  var defaultValue: String?
  
  static var parameterSummary: some ParameterSummary {
    Summary("Get value from \(\.$result) at \(\.$index)") {
      \.$defaultValue
    }
  }
  
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    if self.result.strings.indices.contains(self.index) {
      let string = self.result.strings[self.index]
      if let defaultValue, string.isEmpty {
        return .result(value: defaultValue)
      } else {
        return .result(value: string)
      }
    } else if let defaultValue {
      return .result(value: defaultValue)
    } else {
      throw ReferenceError.indexOutOfRange(index: self.index,
                                           min: 0,
                                           max: self.result.strings.count - 1)
    }
  }
}
