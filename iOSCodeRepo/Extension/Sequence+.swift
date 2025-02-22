//
//  Sequence+.swift
//  Test
//
//  Created by xndm on 2024/12/24.
//

import Foundation

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
    
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
    
    func concurrentForEach(
        _ operation: @escaping (Element) async -> Void
    ) async {
        // A task group automatically waits for all of its
        // sub-tasks to complete, while also performing those
        // tasks in parallel:
        await withTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    await operation(element)
                }
            }
        }
    }
}

extension Sequence {
    func sorted<T: Comparable>(
        by keyPath: KeyPath<Element, T>,
        using comparator: (T, T) -> Bool = (<)
    ) -> [Element] {
        sorted { a, b in
            comparator(a[keyPath: keyPath], b[keyPath: keyPath])
        }
    }
}

struct SortDescriptor<Value> {
    var comparator: (Value, Value) -> ComparisonResult
}

extension SortDescriptor {
    static func keyPath<T: Comparable>(_ keyPath: KeyPath<Value, T>) -> Self {
        Self { rootA, rootB in
            let valueA = rootA[keyPath: keyPath]
            let valueB = rootB[keyPath: keyPath]
            
            guard valueA != valueB else {
                return .orderedSame
            }
            
            return valueA < valueB ? .orderedAscending : .orderedDescending
        }
    }
}

enum SortOrder {
    case ascending
    case descending
}

extension Sequence {
    func sorted(using descriptors: [SortDescriptor<Element>],
                order: SortOrder) -> [Element] {
        sorted { valueA, valueB in
            for descriptor in descriptors {
                let result = descriptor.comparator(valueA, valueB)
                
                switch result {
                case .orderedSame:
                    // Keep iterating if the two elements are equal,
                    // since that'll let the next descriptor determine
                    // the sort order:
                    break
                case .orderedAscending:
                    return order == .ascending
                case .orderedDescending:
                    return order == .descending
                }
            }
            
            // If no descriptor was able to determine the sort
            // order, we'll default to false (similar to when
            // using the '<' operator with the built-in API):
            return false
        }
    }
}

extension Sequence {
    func sorted(using descriptors: SortDescriptor<Element>...) -> [Element] {
        sorted(using: descriptors, order: .ascending)
    }
}

extension Sequence {
    func contains<T: Sequence>(
        _ values: T,
        matchedBy matcher: (Element, T.Element) -> Bool
    ) -> Bool {
        values.allSatisfy { value in
            contains(where: { matcher($0, value) })
        }
    }
}

extension Sequence {
    func sum<N: Numeric>(by valueProvider: (Element) -> N) -> N {
        return reduce(0) { result, element in
            return result + valueProvider(element)
        }
    }
}

extension StringProtocol {
    func trimmingLeadingNumbers() -> SubSequence {
        drop(while: { $0.isNumber })
    }
}

extension BidirectionalCollection {
    func page(withIndex pageIndex: Int, size: Int) -> SubSequence {
        dropFirst(pageIndex * size).prefix(size)
    }
}

struct WrappedSequence<Wrapped: Sequence, Element>: Sequence {
    typealias IteratorFunction = (inout Wrapped.Iterator) -> Element?
    
    private let wrapped: Wrapped
    private let iterator: IteratorFunction
    
    init(wrapping wrapped: Wrapped,
         iterator: @escaping IteratorFunction) {
        self.wrapped = wrapped
        self.iterator = iterator
    }
    
    func makeIterator() -> AnyIterator<Element> {
        var wrappedIterator = wrapped.makeIterator()
        return AnyIterator { self.iterator(&wrappedIterator) }
    }
}

extension Sequence {
    func prefixed(
        with prefixElements: Element...
    ) -> WrappedSequence<Self, Element> {
        var prefixIndex = 0
        
        return WrappedSequence(wrapping: self) { iterator in
            // If we still have prefixed elements left to serve,
            // then return the next one by incrementing our index:
            guard prefixIndex >= prefixElements.count else {
                let element = prefixElements[prefixIndex]
                prefixIndex += 1
                return element
            }
            
            // Otherwise, return an element from our underlying
            // sequence's own iterator:
            return iterator.next()
        }
    }
    
    func suffixed(
        with suffixElements: Element...
    ) -> WrappedSequence<Self, Element> {
        var suffixIndex = 0
        
        return WrappedSequence(wrapping: self) { iterator in
            guard let next = iterator.next() else {
                // This is our exit condition, in which we return
                // nil after both the underlying iteration, and
                // the suffixed one, have been completed:
                guard suffixIndex < suffixElements.count else {
                    return nil
                }
                
                let element = suffixElements[suffixIndex]
                suffixIndex += 1
                return element
            }
            
            return next
        }
    }
}

extension Sequence {
    typealias Segment = (
        previous: Element?,
        current: Element,
        next: Element?
    )
    
    var segmented: WrappedSequence<Self, Segment> {
        var previous: Element?
        var current: Element?
        var endReached = false
        
        return WrappedSequence(wrapping: self) { iterator in
            // Here our exit condition is either that we've
            // reached the end of the underlying sequence, or
            // that a first current element couldn't be created,
            // because the sequence was empty.
            guard !endReached,
                  let element = current ?? iterator.next() else {
                return nil
            }
            
            let next = iterator.next()
            let segment = (previous, element, next)
            
            // Before we return the new segment, we update our
            // iteration state to be ready for the next element:
            previous = element
            current = next
            endReached = (next == nil)
            
            return segment
        }
    }
}

extension Sequence {
    func recursive<S: Sequence>(
        for keyPath: KeyPath<Element, S>
    ) -> WrappedSequence<Self, Element> where S.Iterator == Iterator {
        var parentIterators = [Iterator]()

        func moveUp() -> (iterator: Iterator, element: Element)? {
            guard !parentIterators.isEmpty else {
                return nil
            }

            var iterator = parentIterators.removeLast()

            guard let element = iterator.next() else {
                // We'll keep moving up our chain of parents
                // until we find one that can be advanced to
                // its next element:
                return moveUp()
            }

            return (iterator, element)
        }

        return WrappedSequence(wrapping: self) { iterator in
            // We either use the current iterator's next element,
            // or we move up the chain of parent iterators in
            // order to obtain the next element in the sequence:
            let element = iterator.next() ?? {
                return moveUp().map {
                    iterator = $0
                    return $1
                }
            }()

            // Our recursion is performed depth-first, meaning
            // that we'll dive as deep as possible within the
            // sequence before advancing to the next element on
            // the level above.
            if let nested = element?[keyPath: keyPath].makeIterator() {
                let parent = iterator
                parentIterators.append(parent)
                iterator = nested
            }

            return element
        }
    }
}
