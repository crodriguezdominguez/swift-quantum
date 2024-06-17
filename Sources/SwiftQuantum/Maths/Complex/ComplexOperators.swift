//
//  exops.swift
//  complex
//
//  Created by Dan Kogai on 1/16/16.
//  Copyright © 2016 Dan Kogai. All rights reserved.
//
// Non-builtin operators
#if os(Linux)
    import Glibc
#else
    import Foundation
#endif
// **, **= // pow(lhs, rhs)
precedencegroup PowPrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}
infix operator ** : PowPrecedence

precedencegroup PowAssignmentPrecedence {
    associativity: right
    higherThan: AssignmentPrecedence
}

infix operator **= : PowAssignmentPrecedence
public func **(lhs:Double, rhs:Double) -> Double {
    return Double.pow(lhs, rhs)
}
public func ** (lhs:Complex, rhs:Complex) -> Complex {
    return pow(lhs, rhs)
}
public func ** (lhs:Double, rhs:Complex) -> Complex {
    return pow(lhs, rhs)
}
public func ** (lhs:Complex, rhs:Double) -> Complex {
    return pow(lhs, rhs)
}
public func **= (lhs:inout Double, rhs:Double) {
    lhs = Double.pow(lhs, rhs)
}
public func **= (lhs:inout Complex, rhs:Complex) {
    lhs = pow(lhs, rhs)
}
public func **= (lhs:inout Complex, rhs:Double) {
    lhs = pow(lhs, rhs)
}

precedencegroup SimilarityPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

// =~ // approximate comparisons
infix operator =~ : SimilarityPrecedence

public func =~ (lhs:Double, rhs:Double) -> Bool {
    if lhs == rhs { return true }
    // if either side is zero, simply compare to epsilon
    if rhs == 0 { return abs(lhs) < Double.EPSILON }
    if lhs == 0 { return abs(rhs) < Double.EPSILON }
    // sign must match
    if (lhs.sign == .minus) != (rhs.sign == .minus) { return false }
    // delta / average < epsilon
    let num = lhs - rhs
    let den = lhs + rhs
    return abs(num/den) < 2.0*Double.EPSILON
}
public func =~ (lhs:Complex, rhs:Complex) -> Bool {
    return lhs.abs =~ rhs.abs
}
public func =~ (lhs:Complex, rhs:Double) -> Bool {
    return lhs.abs =~ abs(rhs)
}
public func =~ (lhs:Double, rhs:Complex) -> Bool {
    return abs(lhs) =~ rhs.abs
}

// !~
infix operator !~ : SimilarityPrecedence
public func !~ (lhs:Double, rhs:Double) -> Bool {
    return !(lhs =~ rhs)
}
public func !~ (lhs:Complex, rhs:Complex) -> Bool {
    return !(lhs =~ rhs)
}
public func !~ (lhs:Complex, rhs:Double) -> Bool {
    return !(lhs =~ rhs)
}
public func !~ (lhs:Double, rhs:Complex) -> Bool {
    return !(lhs =~ rhs)
}
