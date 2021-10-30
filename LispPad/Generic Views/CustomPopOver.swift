//
//  CustomPopOver.swift
//  LispPad
//
//  Created by Matthias Zenger on 25/10/2021.
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
  
  struct Wrapper<Content: View> : UIViewControllerRepresentable {
    @Binding var showPopover: Bool
    let popoverSize: CGSize?
    let popoverContent: () -> Content
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<Wrapper<Content>>)
                                -> WrapperViewController<Content> {
      return WrapperViewController(
          popoverSize: popoverSize,
          popoverContent: popoverContent) {
              self.showPopover = false
      }
    }
    
    func updateUIViewController(_ uiViewController: WrapperViewController<Content>,
                                context: UIViewControllerRepresentableContext<Wrapper<Content>>) {
      uiViewController.updateSize(popoverSize)
      if showPopover {
        uiViewController.showPopover()
      } else {
        uiViewController.hidePopover()
      }
    }
  }
  
  class WrapperViewController<PopoverContent: View>: UIViewController,
                                                     UIPopoverPresentationControllerDelegate {
    var popoverSize: CGSize?
    let popoverContent: () -> PopoverContent
    let onDismiss: () -> Void
    var popoverVC: UIViewController?
    
    init(popoverSize: CGSize?,
         popoverContent: @escaping () -> PopoverContent,
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
