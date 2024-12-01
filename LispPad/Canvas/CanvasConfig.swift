//
//  CanvasConfig.swift
//  LispPad
//
//  Created by Matthias Zenger on 11/11/2023.
//  Copyright © 2023 Matthias Zenger. All rights reserved.
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
import UIKit
import LispKit
import Atomics

final class CanvasConfig: ObservableObject, Identifiable, Equatable, Hashable {
  static let empty = CanvasConfig(name: "None",
                                  size: CGSize(width: 10, height: 10),
                                  background: .clear,
                                  drawing: Drawing())
  
  private static let counter = ManagedAtomic<Int>(0)
  
  struct State: Equatable {
    let id: Int
    let size: CGSize
    let scale: CGFloat
    let zoom: CGFloat
    let drawing: Drawing
    let drawingInstr: Int
    
    var drawingId: UInt {
      return self.drawing.identity
    }
    
    var drawScale: CGFloat {
      return self.scale * self.zoom
    }
  }
  
  let id: Int
  @Published var name: String
  @Published var size: CGSize
  @Published var scale: CGFloat
  @Published var zoom: CGFloat
  @Published var background: UIColor?
  @Published var drawing: Drawing
  
  init(name: String? = nil,
       size: CGSize = .init(width: 1000, height: 1000),
       scale: CGFloat = 1.0,
       background: UIColor? = nil,
       drawing: Drawing) {
    let id = CanvasConfig.counter.loadThenWrappingIncrement(ordering: .relaxed)
    self.id = id
    self.name = name ?? "Canvas \(id)"
    self.size = size
    self.scale = scale
    self.zoom = 1.0
    self.background = background
    self.drawing = drawing
  }
  
  var state: State {
    return State(id: self.id,
                 size: self.size,
                 scale: self.scale,
                 zoom: self.zoom,
                 drawing: self.drawing,
                 drawingInstr: self.drawing.numInstructions)
  }
  
  var width: CGFloat {
    return self.size.width * self.zoom
  }
  
  var height: CGFloat {
    return self.size.height * self.zoom
  }
  
  var drawScale: CGFloat {
    return self.scale * self.zoom
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
  
  static func == (lhs: CanvasConfig, rhs: CanvasConfig) -> Bool {
    return lhs.id == rhs.id
  }
}
