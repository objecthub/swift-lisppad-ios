//
//  ImageManager.swift
//  LispPad
//
//  Created by Matthias Zenger on 03/06/2021.
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

import UIKit
import PhotosUI
import SwiftUI
import LispKit

class ImageManager: NSObject {
  let condition = NSCondition()
  var completed = false
  var images: [UIImage?] = []
  var data: [Data?] = []
  var error: Error? = nil
  
  func writeImageToLibrary(_ image: UIImage, async: Bool = false) throws {
    UIImageWriteToSavedPhotosAlbum(image,
                                   self,
                                   #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)),
                                   nil)
    if !async {
      self.condition.lock()
      defer {
        self.condition.unlock()
      }
      while !self.completed {
        self.condition.wait()
      }
      if let error = self.error {
        throw error
      }
    }
  }
  
  func loadImagesFromLibrary() throws -> [UIImage?] {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    while !self.completed {
      self.condition.wait()
    }
    if let error = self.error {
      throw error
    }
    return self.images
  }
  
  func loadDataFromLibrary() throws -> [Data?] {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    while !self.completed {
      self.condition.wait()
    }
    if let error = self.error {
      throw error
    }
    return self.data
  }
  
  func completeLoadImageFromLibrary(images: [UIImage?] = [],
                                    data: [Data?] = [],
                                    error: Error? = nil) {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    self.images = images
    self.data = data
    self.error = error
    self.completed = true
    self.condition.signal()
  }
  
  @objc func imageSaved(_ image: UIImage,
                        didFinishSavingWithError error: Error?,
                        contextInfo: UnsafeRawPointer) {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    self.error = error
    self.completed = true
    self.condition.signal()
  }
}

func iconImage(for drawing: Drawing,
               width: CGFloat = 720.0,
               height: CGFloat = 720.0,
               scale: CGFloat = 2.0,
               extra: CGFloat = 1.0,
               renderingWidth: CGFloat = 1000.0,
               renderingHeight: CGFloat = 1000.0,
               minContentWidth: CGFloat = 200.0,
               minContentHeight: CGFloat = 200.0,
               contentOnly: Bool = true) -> UIImage? {
  guard let context = CGContext(data: nil,
                                width: Int(renderingWidth * scale),
                                height: Int(renderingHeight * scale),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: Color.colorSpaceName,
                                bitmapInfo: CGBitmapInfo(rawValue:
                                              CGImageAlphaInfo.premultipliedFirst.rawValue)
                                            .union(.byteOrder32Little).rawValue) else {
    return nil
  }
  context.translateBy(x: 0.0, y: CGFloat(renderingHeight * scale))
  context.scaleBy(x: scale, y: -scale)
  context.scaleBy(x: extra, y: extra)
  UIGraphicsPushContext(context)
  defer {
    UIGraphicsPopContext()
  }
  drawing.draw()
  guard let cgImage = context.makeImage() else {
    return nil
  }
  let image = UIImage(cgImage: cgImage, scale: CGFloat(scale), orientation: .up)
  if contentOnly {
    guard let box = contentBox(image: image) else {
      return nil
    }
    let scaledBox = scaleUp(box: box, minWidth: minContentWidth, minHeight: minContentHeight)
    return crop(image: image,
                rect: scaledBox,
                size: fit(size: scaledBox.size, maxWidth: width, maxHeight: height))
  } else {
    return image
  }
}

private func fit(size: CGSize, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
  var scale: CGFloat = maxWidth / size.width
  if size.height * scale > maxHeight {
    scale = maxHeight / size.height
  }
  return CGSize(width: size.width * scale, height: size.height * scale)
}

private func scaleUp(box: CGRect, minWidth: CGFloat, minHeight: CGFloat) -> CGRect {
  let scale = max(minWidth / box.width, minHeight / box.height)
  guard scale > 1.0 else {
    return box
  }
  return CGRect(x: notNeg(box.origin.x - ((box.width * scale) - box.width) / 2.0),
                y: notNeg(box.origin.y - ((box.height * scale) - box.height) / 2.0),
                width: box.width * scale,
                height: box.height * scale)
}

private func notNeg(_ x: CGFloat) -> CGFloat {
  return x < 0.0 ? 0.0 : x
}

private func contentBox(image: UIImage) -> CGRect? {
  guard let cgImage = image.cgImage,
        let imageData = cgImage.dataProvider?.data else {
    return nil
  }
  let scale = image.scale
  let width = cgImage.width
  let height = cgImage.height
  let pixels: UnsafePointer<UInt8> = CFDataGetBytePtr(imageData)
  var left = CGPoint(x: 0, y: 0)
  loop: for x in 0..<width {
    for y in 0..<height {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        left = CGPoint(x: x > 0 ? x - 1 : x, y: y)
        break loop
      }
    }
  }
  var top = CGPoint(x: 0, y: 0)
  loop: for y in 0..<height {
    for x in 0..<width {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        top = CGPoint(x: x, y: y > 0 ? y - 1 : y)
        break loop
      }
    }
  }
  var bottom = CGPoint(x: width - 1, y: height - 1)
  loop: for y in stride(from: height - 1, through: 0, by: -1) {
    for x in stride(from: width - 1, through: 0, by: -1) {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        bottom = CGPoint(x: x, y: y < height - 1 ? y + 1 : y)
        break loop
      }
    }
  }
  var right = CGPoint(x: width - 1, y: height - 1)
  loop: for x in stride(from: width - 1, through: 0, by: -1) {
    for y in stride(from: height - 1, through: 0, by: -1) {
      if pixels[(x + y * width) * 4 + 3] != 0 {
        right = CGPoint(x: x < width - 1 ? x + 1 : x, y: y)
        break loop
      }
    }
  }
  return CGRect(x: left.x / scale,
                y: top.y / scale,
                width: (right.x - left.x) / scale,
                height: (bottom.y - top.y) / scale)
}

private func crop(image: UIImage, rect: CGRect, size: CGSize?) -> UIImage? {
  let imageSize = size ?? image.size
  let imageScale = image.scale
  // Create a new bitmap
  guard let context = CGContext(data: nil,
                                width: Int(imageSize.width * imageScale),
                                height: Int(imageSize.height * imageScale),
                                bitsPerComponent: 8,
                                bytesPerRow: 0,
                                space: Color.colorSpaceName,
                                bitmapInfo: CGBitmapInfo(rawValue:
                                              CGImageAlphaInfo.premultipliedFirst.rawValue)
                                            .union(.byteOrder32Little).rawValue) else {
    return nil
  }
  // Flip the coordinate system
  context.translateBy(x: 0.0, y: imageSize.height * imageScale)
  context.scaleBy(x: imageScale, y: -imageScale)
  // Scale to match the required size
  context.scaleBy(x: imageSize.width / rect.width, y: imageSize.height / rect.height)
  UIGraphicsPushContext(context)
  defer {
    UIGraphicsPopContext()
  }
  // Draw image into the bitmap
  image.draw(at: CGPoint(x: -rect.origin.x, y: -rect.origin.y),
             blendMode: .copy,
             alpha: 1.0)
  // Create a new image from the bitmap
  guard let cgImage = context.makeImage() else {
    return nil
  }
  let image = UIImage(cgImage: cgImage, scale: imageScale, orientation: .up)
  return image
}
