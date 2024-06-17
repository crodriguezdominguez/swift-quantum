//
//  QuBitOperators.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 30/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public func ^(left:QuBit, right:QuBit) -> QuBit {
    let matrix = ControlledNotGate().transform(input: (left, right))
    let (quBits, _) = try! QuMeasurer(input: matrix).mostProbableQuBits()
    
    return quBits.last!
}

public prefix func ~(quBit:QuBit) -> QuBit {
    return QuNotGate().transform(input: quBit)
}

public func &(left:QuBit, right:QuBit) -> QuBit {
    let matrix = ToffoliCCNotGate().transform(input: (left, right, .grounded))
    let (quBits, _) = try! QuMeasurer(input: matrix).mostProbableQuBits()
    
    return quBits.last!
}

public func |(left:QuBit, right:QuBit) -> QuBit {
    let matrix = ToffoliCCNotGate().transform(input: (~left, ~right, .excited))
    let (quBits, _) = try! QuMeasurer(input: matrix).mostProbableQuBits()
    
    return quBits.last!
}
