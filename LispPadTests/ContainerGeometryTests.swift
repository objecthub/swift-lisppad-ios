//
//  LispPadTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 02/10/2026.
//

import Testing
import SwiftUI
@testable import LispPad


@Suite("Container geometry")
struct ContainerGeometryTests {
  
  @Test("Navigation bar width: Basics")
  func testNavigationBarWidth() async throws {
    let cg = ContainerGeometry(size: CGSize(width: 490, height: 630),
                               safeAreaInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                               reserved: [CGRect(x: 400, y: 0, width: 90, height: 60)])
    #expect(leftNavBarWidth(cg, frac: 0.5) == 245)
    #expect(rightNavBarWidth(cg, frac: 0.5) == 155)
    #expect(leftNavBarWidth(cg, frac: 1.0) == 400)
    #expect(rightNavBarWidth(cg, frac: 1.0) == 400)
    #expect(leftNavBarWidth(cg, frac: 0.0) == 0)
    #expect(rightNavBarWidth(cg, frac: 0.0) == 0)
  }
  
  @Test("Navigation bar width: Asymmetric")
  func testNavigationBarWidthAsymmetric() async throws {
    var cg = ContainerGeometry(size: CGSize(width: 490, height: 630),
                               safeAreaInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                               reserved: [CGRect(x: 400, y: 0, width: 90, height: 60)])
    #expect(leftNavBarWidth(cg, frac: 0.6) == 294)
    #expect(rightNavBarWidth(cg, frac: 0.4) == 106)
    cg = ContainerGeometry(size: CGSize(width: 490, height: 630),
                           safeAreaInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                           reserved: [CGRect(x: 400, y: 0, width: 90, height: 60),
                                      CGRect(x: 20, y: 0, width: 30, height: 20)])
    #expect(leftNavBarWidth(cg, frac: 0.6) == 264)
    #expect(rightNavBarWidth(cg, frac: 0.4) == 106)
    cg = ContainerGeometry(size: CGSize(width: 490, height: 630),
                           safeAreaInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                           reserved: [CGRect(x: 400, y: 0, width: 90, height: 60),
                                      CGRect(x: 20, y: 0, width: 30, height: 20),
                                      CGRect(x: 264, y: 5, width: 40, height: 20)])
    #expect(leftNavBarWidth(cg, frac: 0.6) == 234)
    #expect(rightNavBarWidth(cg, frac: 0.4) == 96)
    #expect(leftNavBarWidth(cg, frac: 0.7) == 273)
    #expect(rightNavBarWidth(cg, frac: 0.3).isClose(to: 57.0, tolerance: 0.00001))
  }
  
  @Test("Navigation bar width: Insets")
  func testNavigationBarWidthInsets() async throws {
    var cg = ContainerGeometry(size: CGSize(width: 490, height: 630),
                               safeAreaInsets: .init(top: 0, leading: 20, bottom: 0, trailing: 10),
                               reserved: [CGRect(x: 400, y: 0, width: 90, height: 60)])
    #expect(leftNavBarWidth(cg, frac: 0.6) == 294)
    #expect(rightNavBarWidth(cg, frac: 0.4) == 106)
    cg = ContainerGeometry(size: CGSize(width: 490, height: 630),
                           safeAreaInsets: .init(top: 0, leading: 20, bottom: 0, trailing: 10),
                           reserved: [CGRect(x: 400, y: 0, width: 90, height: 60),
                                      CGRect(x: 10, y: 0, width: 30, height: 20)])
    #expect(leftNavBarWidth(cg, frac: 0.6) == 274)
    #expect(rightNavBarWidth(cg, frac: 0.4) == 106)
    cg = ContainerGeometry(size: CGSize(width: 490, height: 630),
                           safeAreaInsets: .init(top: 0, leading: 20, bottom: 0, trailing: 10),
                           reserved: [CGRect(x: 400, y: 0, width: 90, height: 60),
                                      CGRect(x: 10, y: 0, width: 30, height: 20),
                                      CGRect(x: 264, y: 5, width: 40, height: 20)])
    #expect(leftNavBarWidth(cg, frac: 0.6) == 234)
    #expect(rightNavBarWidth(cg, frac: 0.4) == 106)
    #expect(leftNavBarWidth(cg, frac: 0.7) == 283)
    #expect(rightNavBarWidth(cg, frac: 0.3).isClose(to: 57.0, tolerance: 0.00001))
  }
  
  @Test("Navigation bar width: iPhone Duo")
  func testNavigationBarIPhoneDuo() async throws {
    var cg = ContainerGeometry(size: CGSize(width: 951.0, height: 543.0),
                               safeAreaInsets: .init(top: 82.0, leading: 0.0, bottom: 44.0, trailing: 0.0),
                               reserved: [CGRect(x: 817.0, y: -82.0, width: 134.0, height: 82.0)])
    #expect(leftNavBarWidth(cg, frac: 0.5) == 475.5)
    #expect(rightNavBarWidth(cg, frac: 0.5) == 341.5)
  }
  
  private func leftNavBarWidth(_ cg: ContainerGeometry, frac: CGFloat) -> CGFloat {
    return cg.navigationBarWidth(left: true, masterWidthFraction: frac)
  }
  
  private func rightNavBarWidth(_ cg: ContainerGeometry, frac: CGFloat) -> CGFloat {
    return cg.navigationBarWidth(left: false, masterWidthFraction: (1.0 - frac))
  }
}


extension FloatingPoint {
  func isClose(to other: Self, tolerance: Self) -> Bool {
    abs(self - other) <= tolerance
  }
}
