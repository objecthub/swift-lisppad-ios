//
//  ThreadUtil.swift
//  LispPad
//
//  Created by Matthias Zenger on 16/10/2024.
//

import Foundation

func doOnMainThread<T>(proc: () -> T) -> T {
  if Thread.isMainThread {
    return proc()
  } else {
    return DispatchQueue.main.sync(execute: proc)
  }
}

func doOnMainThreadAsync(proc: @escaping () -> Void) {
  if Thread.isMainThread {
    proc()
  } else {
    DispatchQueue.main.async(execute: proc)
  }
}
