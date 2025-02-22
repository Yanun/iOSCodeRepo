//
//  Predicate.swift
//  Test
//
//  Created by xndm on 2025/1/10.
//

import Foundation

struct Predicate<Target> {
    var matches: (Target) -> Bool

    init(matcher: @escaping (Target) -> Bool) {
        matches = matcher
    }
}

func ==<T, V: Equatable>(lhs: KeyPath<T, V>, rhs: V) -> Predicate<T> {
    Predicate { $0[keyPath: lhs] == rhs }
}

prefix func !<T>(rhs: KeyPath<T, Bool>) -> Predicate<T> {
    rhs == false
}

func ><T, V: Comparable>(lhs: KeyPath<T, V>, rhs: V) -> Predicate<T> {
    Predicate { $0[keyPath: lhs] > rhs }
}

func <<T, V: Comparable>(lhs: KeyPath<T, V>, rhs: V) -> Predicate<T> {
    Predicate { $0[keyPath: lhs] < rhs }
}

func &&<T>(lhs: Predicate<T>, rhs: Predicate<T>) -> Predicate<T> {
    Predicate { lhs.matches($0) && rhs.matches($0) }
}

func ||<T>(lhs: Predicate<T>, rhs: Predicate<T>) -> Predicate<T> {
    Predicate { lhs.matches($0) || rhs.matches($0) }
}

func ~=<T, V: Collection>(
    lhs: KeyPath<T, V>, rhs: V.Element
) -> Predicate<T> where V.Element: Equatable {
    Predicate { $0[keyPath: lhs].contains(rhs) }
}
