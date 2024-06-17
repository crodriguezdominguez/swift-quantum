//
//  QuRegisterOperators.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 30/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public postfix func ++(register:QuRegister) -> QuRegister {
    return try! IncrementerCircuit(numberOfInputs: register.count).increment(register)
}

public postfix func --(register:QuRegister) -> QuRegister {
    return try! DecrementerCircuit(numberOfInputs: register.count).decrement(register)
}

public func +(left:QuRegister, right:QuRegister) -> QuRegister {
    let countResult = max(left.count, right.count)
    let newLeft = expandRegister(left, to: countResult)
    let newRight = expandRegister(right, to: countResult)
    
    let fullAdder = FullTwoQuBitsAdderCircuit()
    var result = [QuBit](repeating: .grounded, count: countResult)
    var carry = QuBit.grounded
    for k in (0..<countResult).reversed() {
        (result[k], carry) = fullAdder.add(first: newLeft[k], second: newRight[k], carry: carry)
    }
    
    return QuRegister(quBits: [carry]+result)
}

public func -(left:QuRegister, right:QuRegister) -> QuRegister {
    let countResult = max(left.count, right.count)
    let newLeft = expandRegister(left, to: countResult)
    let newRight = expandRegister(right, to: countResult)
    
    let fullSubs = FullTwoQuBitsSubtractorCircuit()
    var result = [QuBit](repeating: .grounded, count: countResult)
    var borrow = QuBit.grounded
    for k in (0..<countResult).reversed() {
        (result[k], borrow) = fullSubs.subtract(first: newLeft[k], second: newRight[k], borrow: borrow)
    }
    
    return QuRegister(quBits: result)
}

public func &(left:QuRegister, right:QuRegister) -> QuRegister {
    let countResult = max(left.count, right.count)
    let newLeft = expandRegister(left, to: countResult)
    let newRight = expandRegister(right, to: countResult)
    
    var result = [QuBit](repeating: .grounded, count: countResult)
    for k in 0..<countResult {
        result[k] = newLeft[k] & newRight[k]
    }
    
    return QuRegister(quBits: result)
}

public func |(left:QuRegister, right:QuRegister) -> QuRegister {
    let countResult = max(left.count, right.count)
    let newLeft = expandRegister(left, to: countResult)
    let newRight = expandRegister(right, to: countResult)
    
    var result = [QuBit](repeating: .grounded, count: countResult)
    for k in 0..<countResult {
        result[k] = newLeft[k] | newRight[k]
    }
    
    return QuRegister(quBits: result)
}

public func ^(left:QuRegister, right:QuRegister) -> QuRegister {
    let countResult = max(left.count, right.count)
    let newLeft = expandRegister(left, to: countResult)
    let newRight = expandRegister(right, to: countResult)
    
    var result = [QuBit](repeating: .grounded, count: countResult)
    for k in 0..<countResult {
        result[k] = newLeft[k] ^ newRight[k]
    }
    
    return QuRegister(quBits: result)
}

public prefix func ~(register:QuRegister) -> QuRegister {
    var result = [QuBit](repeating: .grounded, count: register.count)
    for k in 0..<register.count {
        result[k] = ~register[k]
    }
    
    return QuRegister(quBits: result)
}

private func expandRegister(_ register:QuRegister, to nQuBits:Int) -> QuRegister {
    guard nQuBits > register.count else {
        return register
    }
    
    let padding = nQuBits-register.count
    let zeros = [QuBit](repeating: .grounded, count: padding)
    
    return QuRegister(quBits: zeros+register.quBits)
}
