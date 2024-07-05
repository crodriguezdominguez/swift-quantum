//
//  GroverCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 14/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public struct GroverCircuit: QuCircuitRepresentable {
    public private(set) var quCircuit: QuCircuit
    
    public init(oracle: QuBitTransformer) {
        let name = oracle.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        let numberOfInputs = oracle.numberOfInputs
        quCircuit = QuCircuit(name: "|Grover-\(oracle.numberOfInputs-1) \(name)|", numberOfInputs: oracle.numberOfInputs)
        
        let h = HadamardGate()
        let groover = GroverCircuit.groverOperator(forNumberOfInputs: numberOfInputs-1)
        
        var time = 0
        for k in 0..<numberOfInputs {
            try! quCircuit.append(transformer: h, atTime: time, forInputAtIndices: [k])
        }
        time += 1
        
        let iterations = Int(ceil(sqrt(Double(numberOfInputs))))
        let inputs = [Int](0..<numberOfInputs)
        let reducedInputs = [Int](0..<numberOfInputs-1)
        for _ in 0..<iterations {
            try! quCircuit.append(transformer: oracle, atTime: time, forInputAtIndices: inputs)
            time += 1
            
            try! quCircuit.append(transformer: groover, atTime: time, forInputAtIndices: reducedInputs)
            time += 1
        }
        
        try! quCircuit.append(transformer: h, atTime: time, forInputAtIndices: [numberOfInputs-1])
        try! quCircuit.append(transformer: PauliXGate(), atTime: time+1, forInputAtIndices: [numberOfInputs-1])
    }
    
    public func evaluate() -> QuAmplitudeMatrix {
        var quBits = [QuBit](repeating: .grounded, count: self.numberOfInputs-1)
        quBits.append(.excited)
        
        return try! quCircuit.transform(input: QuRegister(quBits: quBits))
    }
    
    public static func groverOperator(forNumberOfInputs numberOfInputs:Int) -> QuCircuit {
        var circuit = QuCircuit(name: "Grov", numberOfInputs: numberOfInputs)
        let h = HadamardGate()
        let x = PauliXGate()
        let cz = MultiControlMultiTargetControlledGate(numberOfControlInputs: numberOfInputs-1, targetGate: PauliZGate())
        
        var time = 0
        for k in 0..<numberOfInputs {
            try! circuit.append(transformer: h, atTime: time, forInputAtIndex: k)
        }
        
        time += 1
        for k in 0..<numberOfInputs {
            try! circuit.append(transformer: x, atTime: time, forInputAtIndex: k)
        }
        
        time += 1
        
        let inputs = [Int](0..<numberOfInputs)
        try! circuit.append(transformer: cz, atTime: time, forInputAtIndices: inputs)
        
        time += 1
        for k in 0..<numberOfInputs {
            try! circuit.append(transformer: x, atTime: time, forInputAtIndex: k)
        }
        
        time += 1
        for k in 0..<numberOfInputs {
            try! circuit.append(transformer: h, atTime: time, forInputAtIndex: k)
        }
        
        return circuit
    }
}
