//
//  Zoomable.swift
//  LispPad
//
//  Created by Matthias Zenger on 18/10/2025.
//
//  This code is based on https://github.com/ryohey/Zoomable by ryohey
//  
//  MIT License
//
//  Copyright (c) 2023 ryohey
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

import SwiftUI

struct ZoomableModifier: ViewModifier {
  let minZoomScale: CGFloat
  let maxZoomScale: CGFloat
  
  @State private var transform: CGAffineTransform = .identity
  @State private var contentSize: CGSize = .zero
  @Binding var scale: CGFloat
  
  func body(content: Content) -> some View {
    content
      .background(alignment: .topLeading) {
        GeometryReader { proxy in
          Color.clear
            .onAppear {
              contentSize = proxy.size
            }
        }
      }
      .scaleEffect(x: transform.scaleX, y: transform.scaleY, anchor: .zero)
      .offset(x: transform.tx, y: transform.ty)
      .gesture(magnificationGesture)
  }
  
  private var magnificationGesture: some Gesture {
    MagnifyGesture(minimumScaleDelta: 0)
      .onChanged { value in
        withAnimation(.interactiveSpring) {
          transform = .anchoredScale(scale: value.magnification,
                                     anchor: CGPoint(x: value.startAnchor.x * contentSize.width,
                                                     y: value.startAnchor.y * contentSize.height))
        }
      }
      .onEnded { _ in
        onEndGesture()
      }
  }
  
  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        withAnimation(.interactiveSpring) {
          transform = .identity.translatedBy(
            x: value.translation.width / max(transform.scaleX, .leastNonzeroMagnitude),
            y: value.translation.height / max(transform.scaleY, .leastNonzeroMagnitude))
        }
      }
      .onEnded { _ in
        onEndGesture()
      }
  }
  
  private func onEndGesture() {
    let newTransform = limitTransform(transform)
    withAnimation(.snappy(duration: 0.1)) {
      transform = .identity
      scale = newTransform.scaleX * scale
    }
  }
  
  private func limitTransform(_ transform: CGAffineTransform) -> CGAffineTransform {
    let scaleX = transform.scaleX
    let scaleY = transform.scaleY
    var capped = transform
    var currentScale = min(scaleX, scaleY)
    if currentScale < minZoomScale {
      let factor = minZoomScale / currentScale
      let contentCenter = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
      let capTransform = CGAffineTransform.anchoredScale(scale: factor, anchor: contentCenter)
      capped = capped.concatenating(capTransform)
    } else {
      currentScale = max(scaleX, scaleY)
      if currentScale > maxZoomScale {
        let factor = maxZoomScale / currentScale
        let contentCenter = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
        let capTransform = CGAffineTransform.anchoredScale(scale: factor, anchor: contentCenter)
        capped = capped.concatenating(capTransform)
      }
    }
    let maxX = -contentSize.width * (capped.scaleX - 1)
    let maxY = -contentSize.height * (capped.scaleY - 1)
    if capped.tx > 0 || capped.tx < maxX || capped.ty > 0 || capped.ty < maxY {
      capped.tx = min(max(capped.tx, maxX), 0)
      capped.ty = min(max(capped.ty, maxY), 0)
    }
    return capped
  }
}

extension View {
  @ViewBuilder
  public func zoomable(minZoomScale: CGFloat = 1,
                       maxZoomScale: CGFloat = 10,
                       scale: Binding<CGFloat>) -> some View {
    modifier(ZoomableModifier(minZoomScale: minZoomScale / scale.wrappedValue,
                              maxZoomScale: maxZoomScale / scale.wrappedValue,
                              scale: scale))
  }
}

extension CGAffineTransform {
  fileprivate static func anchoredScale(scale: CGFloat, anchor: CGPoint) -> CGAffineTransform {
    CGAffineTransform(translationX: anchor.x, y: anchor.y)
      .scaledBy(x: scale, y: scale)
      .translatedBy(x: -anchor.x, y: -anchor.y)
  }
  
  fileprivate var scaleX: CGFloat {
    sqrt(a * a + c * c)
  }
  
  fileprivate var scaleY: CGFloat {
    sqrt(b * b + d * d)
  }
}
