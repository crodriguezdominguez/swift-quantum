//
//  QuTeleportCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 8/8/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public struct QuTeleportationCircuit : QuCircuitRepresentable {
    public private(set) var quCircuit: QuCircuit
    
    public init() {
        quCircuit = QuCircuit(name: "|TEL|", numberOfInputs: 3)
        
        let h = HadamardGate()
        let cnot = ControlledNotGate()
        let cz = UniversalControlledGate(gate: PauliZGate())
        
        try! quCircuit.append(transformer: h, atTime: 0, forInputAtIndex: 1)
        try! quCircuit.append(transformer: cnot, atTime: 1, forInputAtIndices: [1, 2])
        try! quCircuit.append(transformer: cnot, atTime: 2, forInputAtIndices: [0, 1])
        try! quCircuit.append(transformer: h, atTime: 3, forInputAtIndex: 0)
        try! quCircuit.append(transformer: cnot, atTime: 4, forInputAtIndices: [1, 2])
        try! quCircuit.append(transformer: cz, atTime: 5, forInputAtIndices: [0, 2])
        try! quCircuit.append(transformer: h, atTime: 6, forInputAtIndex: 0)
        try! quCircuit.append(transformer: h, atTime: 6, forInputAtIndex: 1)
    }
    
    public func teleport(_ quBit:QuBit) -> QuAmplitudeMatrix {
        let register = QuRegister(quBits: quBit, .grounded, .grounded)
        return try! self.transform(input: register)
    }
}
