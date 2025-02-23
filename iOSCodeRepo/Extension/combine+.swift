//
//  combine+.swift
//  Test
//
//  Created by xndm on 2024/12/25.
//

import Combine
import Foundation

extension Future where Failure == Error {
  convenience init(operation: @escaping () async throws -> Output) {
    self.init { promise in
      Task {
        do {
          let output = try await operation()
          promise(.success(output))
        } catch {
          promise(.failure(error))
        }
      }
    }
  }
}

extension PassthroughSubject where Failure == Error {
  static func emittingValues<T: AsyncSequence>(
    from sequence: T
  ) -> Self where T.Element == Output {
    let subject = Self()

    Task {
      do {
        for try await value in sequence {
          subject.send(value)
        }

        subject.send(completion: .finished)
      } catch {
        subject.send(completion: .failure(error))
      }
    }

    return subject
  }
}

extension Publisher {
  func asyncMap<T>(
    _ transform: @escaping (Output) async -> T
  ) -> Publishers.FlatMap<Future<T, Never>, Self> {
    flatMap { value in
      Future { promise in
        Task {
          let output = await transform(value)
          promise(.success(output))
        }
      }
    }
  }

  func asyncMap<T>(
    _ transform: @escaping (Output) async throws -> T
  ) -> Publishers.FlatMap<Future<T, Error>, Self> {
    flatMap { value in
      Future { promise in
        Task {
          do {
            let output = try await transform(value)
            promise(.success(output))
          } catch {
            promise(.failure(error))
          }
        }
      }
    }
  }

  func asyncMap<T>(
    _ transform: @escaping (Output) async throws -> T
  ) -> Publishers.FlatMap<Future<T, Error>, Publishers.SetFailureType<Self, Error>> {
    flatMap { value in
      Future { promise in
        Task {
          do {
            let output = try await transform(value)
            promise(.success(output))
          } catch {
            promise(.failure(error))
          }
        }
      }
    }
  }
}

extension Publisher {
  func validate(
    using validator: @escaping (Output) throws -> Void
  ) -> Publishers.TryMap<Self, Output> {
    tryMap { output in
      try validator(output)
      return output
    }
  }

  func unwrap<T>(
    orThrow error: @escaping @autoclosure () -> Failure
  ) -> Publishers.TryMap<Self, T> where Output == T? {
    tryMap { output in
      switch output {
      case .some(let value):
        return value
      case nil:
        throw error()
      }
    }
  }
}
