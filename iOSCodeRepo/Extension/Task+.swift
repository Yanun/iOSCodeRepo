//
//  Task+.swift
//  Test
//
//  Created by xndm on 2025/2/11.
//

import Foundation

extension Task where Failure == Error {
  @discardableResult
  static func retrying(
    priority: TaskPriority? = nil,
    maxRetryCount: Int = 3,
    retryDelay: TimeInterval = 1,
    operation: @Sendable @escaping () async throws -> Success
  ) -> Task {
    Task(priority: priority) {
      for _ in 0 ..< maxRetryCount {
        do {
          return try await operation()
        } catch {
          let oneSecond = TimeInterval(1_000_000_000)
          let delay = UInt64(oneSecond * retryDelay)
          try await Task<Never, Never>.sleep(nanoseconds: delay)

          continue
        }
      }

      try Task<Never, Never>.checkCancellation()
      return try await operation()
    }
  }

  static func delayed(
    byTimeInterval delayInterval: TimeInterval,
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Success
  ) -> Task {
    Task(priority: priority) {
      let delay = UInt64(delayInterval * 1_000_000_000)
      try await Task<Never, Never>.sleep(nanoseconds: delay)
      return try await operation()
    }
  }
}
