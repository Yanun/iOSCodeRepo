//
//  Result+.swift
//  Test
//
//  Created by xndm on 2024/12/25.
//

import Foundation

extension Result {
  var value: Success {
    get throws { try get() }
  }
}
