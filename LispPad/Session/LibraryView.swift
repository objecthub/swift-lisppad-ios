//
//  LibraryView.swift
//  LispPad
//
//  Created by Matthias Zenger on 19/03/2021.
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

import SwiftUI
import LispKit

struct LibraryView: View {
  @EnvironmentObject var docManager: DocumentationManager
  @ObservedObject var libManager: LibraryManager
  @State var tapped: Library? = nil
  @State var swiped: Library? = nil
  @State var swipeOffset: CGFloat = 0.0
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVStack(alignment: .leading, spacing: 0) {
        ForEach(self.libManager.libraries, id: \.name) { library in
          Divider()
            .padding(.leading, 16)
          ZStack {
            HStack{
              Color.blue.frame(width: 70).opacity(swiped == library ? 1 : 0)
              Spacer()
            }
            HStack {
              Button(action: {
                withAnimation(.default) {
                  self.tapped = nil
                  self.swiped = nil
                  self.swipeOffset = 0
                }
              }) {
                Image(systemName: "square.and.arrow.down")
                  .font(.headline)
                  .foregroundColor(.white)
              }
              .frame(width: 70)
              Spacer()
            }
            NavigationLink(
              destination: LazyView(LibraryDetailView(name: library.name)),
              tag: library,
              selection: self.$tapped) {
              HStack(spacing: 15) {
                Text(library.name.description)
                  .font(.callout)
                  .foregroundColor(.primary)
                Spacer()
                Text(library.state.description)
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text("〉")
                  .font(.body)
                  .fontWeight(.bold)
                  .foregroundColor(
                    Color(self.docManager.libraryDocumentation(for: library.name) == nil ?
                            .systemBackground :
                            .tertiaryLabel))
              }
              .padding(EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 0))
              .background(Color(UIColor.systemBackground))
              .contentShape(Rectangle())
            }
            .disabled(true)
            .onTapGesture(count: 1) {
              if self.docManager.libraryDocumentation(for: library.name) != nil {
                self.tapped = library
                withAnimation(.default) {
                  self.swipeOffset = 0
                  self.swiped = nil
                }
              }
            }
            .offset(x: self.swiped == library ? self.swipeOffset : 0)
            .gesture(
              DragGesture().onChanged { value in
                withAnimation(.default) {
                  if value.translation.width > 60 {
                    self.swipeOffset = value.translation.width > 180 ? 180 : value.translation.width
                    self.swiped = library
                  } else if value.translation.width < 0 {
                    self.swipeOffset = 0
                    self.swiped = nil
                  } else {
                    self.swipeOffset = value.translation.width
                  }
                }
              }
              .onEnded { value in
                withAnimation(.default) {
                  if value.translation.width > 60 {
                    self.swiped = library
                    self.swipeOffset = 70
                  } else {
                    self.swiped = nil
                    self.swipeOffset = 0
                  }
                }
              }
            )
          }
        }
      }
    }
    .navigationTitle("Libraries")
  }
}
