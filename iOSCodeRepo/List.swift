//
//  List.swift
//  Test
//
//  Created by xndm on 2024/12/14.
//

import Foundation

struct List<Value> {
  private(set) var firstNode: Node?
  private(set) var lastNode: Node?
}

extension List {
  class Node {
    var value: Value
    fileprivate(set) weak var previous: Node?
    fileprivate(set) var next: Node?

    init(value: Value) {
      self.value = value
    }
  }
}

extension List: Sequence {
  func makeIterator() -> AnyIterator<Value> {
    var node = firstNode

    return AnyIterator {
      // Iterate through all of our nodes by continuously
      // moving to the next one and extract its value:
      let value = node?.value
      node = node?.next
      return value
    }
  }
}

extension List {
  @discardableResult
  mutating func append(_ value: Value) -> Node {
    let node = Node(value: value)
    node.previous = lastNode

    lastNode?.next = node
    lastNode = node

    if firstNode == nil {
      firstNode = node
    }

    return node
  }

  mutating func remove(_ node: Node) {
    node.previous?.next = node.next
    node.next?.previous = node.previous

    // Using "triple-equals" we can compare two class
    // instances by identity, rather than by value:
    if firstNode === node {
      firstNode = node.next
    }

    if lastNode === node {
      lastNode = node.previous
    }

    // Completely disconnect the node by removing its
    // sibling references:
    node.next = nil
    node.previous = nil
  }
}
