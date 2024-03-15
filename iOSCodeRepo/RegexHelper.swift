//
//  RegexHelper.swift
//  SwiftCode
//
//  Created by 丁燕军 on 15/12/10.
//  Copyright © 2015年 DYJ. All rights reserved.
//

import Foundation

extension String {

    func isEmail() -> Bool {
        return (self =~ "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$")
    }
}

precedencegroup MatchPrecedence {
    associativity: none
    higherThan: DefaultPrecedence
}

infix operator =~: MatchPrecedence

func =~(lhs: String, rhs: String) -> Bool {
    do {
        return try RegexHelper(rhs).match(lhs)
    } catch _ {
        return false
    }
}

struct RegexHelper {
    let regex: NSRegularExpression
    
    init(_ pattern: String) throws {
        try regex = NSRegularExpression(pattern: pattern,
            options: .caseInsensitive)
    }
    
    func match(_ input: String) -> Bool {
        let matches = regex.matches(in: input,
            options: [],
            range: NSMakeRange(0, input.count))
        return matches.count > 0
    }
}
