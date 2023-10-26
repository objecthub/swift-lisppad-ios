//
//  CustomPopOver.swift
//  LispPad
//
//  Created by Matthias Zenger on 25/10/2021.
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
import SwiftUI

struct CustomPopOver<Content: View, PopoverContent: View>: View {
  @Binding var showPopover: Bool
  var popoverSize: CGSize? = nil
  let content: () -> PopoverContent
  let label: () -> Content
  
  var body: some View {
    label()
    .background(
        Wrapper(showPopover: $showPopover, popoverSize: popoverSize, popoverContent: content)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
    )
  }
  
  struct Wrapper<C: View> : UIViewControllerRepresentable {
    @Binding var showPopover: Bool
    let popoverSize: CGSize?
    let popoverContent: () -> C
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<Wrapper<C>>)
                                -> WrapperViewController<C> {
      return WrapperViewController(
          popoverSize: popoverSize,
          popoverContent: popoverContent) {
              self.showPopover = false
      }
    }
    
    func updateUIViewController(_ uiViewController: WrapperViewController<C>,
                                context: UIViewControllerRepresentableContext<Wrapper<C>>) {
      uiViewController.updateSize(popoverSize)
      if showPopover {
        uiViewController.showPopover()
      } else {
        uiViewController.hidePopover()
      }
    }
  }
  
  class WrapperViewController<PC: View>: UIViewController,
                                         UIPopoverPresentationControllerDelegate {
    var popoverSize: CGSize?
    let popoverContent: () -> PC
    let onDismiss: () -> Void
    var popoverVC: UIViewController?
    
    init(popoverSize: CGSize?,
         popoverContent: @escaping () -> PC,
         onDismiss: @escaping() -> Void) {
      self.popoverSize = popoverSize
      self.popoverContent = popoverContent
      self.onDismiss = onDismiss
      super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
      fatalError("")
    }
    
    func showPopover() {
      guard popoverVC == nil else {
        return
      }
      let vc = UIHostingController(rootView: popoverContent())
      if let size = popoverSize {
        vc.preferredContentSize = size
      }
      vc.modalPresentationStyle = UIModalPresentationStyle.popover
      if let popover = vc.popoverPresentationController {
        popover.sourceView = view
        popover.delegate = self
      }
      popoverVC = vc
      self.present(vc, animated: true, completion: nil)
    }
    
    func hidePopover() {
      guard let vc = popoverVC, !vc.isBeingDismissed else { return }
      vc.dismiss(animated: true, completion: nil)
      popoverVC = nil
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
      popoverVC = nil
      self.onDismiss()
    }
    
    func updateSize(_ size: CGSize?) {
      self.popoverSize = size
      if let vc = popoverVC, let size = size {
        vc.preferredContentSize = size
      }
    }
    
    func adaptivePresentationStyle(for ctrl: UIPresentationController) -> UIModalPresentationStyle {
      return .none
    }
  }
}
