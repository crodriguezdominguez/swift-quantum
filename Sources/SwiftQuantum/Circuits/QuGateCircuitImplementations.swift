//
//  QuGateCircuitImplementations.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 6/8/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public protocol QuCircuitImplementable {
    var circuitImplementation: QuCircuit {get}
}

extension QuFTGate : QuCircuitImplementable {
    public var circuitImplementation: QuCircuit {
        let circuit = QuCircuit(name: inverse ? "|InvQuFT-\(numberOfInputs)|" : "|QuFT-\(numberOfInputs)|", numberOfInputs: self.numberOfInputs)
        
        let h = HadamardGate()
        
        var time = 0
        for k in 0..<numberOfInputs {
            try! circuit.append(transformer: h, atTime: time, forInputAtIndices: [k])
            
            time += 1
            
            if numberOfInputs-k > 1 {
                for phase in 1..<numberOfInputs-k {
                    let exp = pow(2.0, Double(phase))
                    let div = Double.pi / exp
                    let parameter = inverse ? -div : div
                    let gate = UniversalControlledGate(gate: PhaseShiftGate(parameter: parameter))
                    try! circuit.append(transformer: gate, atTime: time, forInputAtIndices: [k+phase, k])
                    
                    time += 1
                }
            }
        }
        
        time += 1
        
        let flip = FlipCircuit(numberOfInputs: numberOfInputs)
        try! circuit.append(transformer: flip, atTime: time, forInputAtIndices: Array(0..<numberOfInputs))
        
        return circuit
    }
}

extension SwapGate : QuCircuitImplementable {
    public var circuitImplementation: QuCircuit {
        let circuit = QuCircuit(name: "|Swap|", numberOfInputs: 2)
        try! circuit.append(transformers: (transformer: ControlledNotGate(), time: 0, inputIndices:[0, 1]),
                           (transformer: ControlledNotGate(), time: 1, inputIndices:[1, 0]),
                           (transformer: ControlledNotGate(), time: 2, inputIndices:[0, 1])
        )
        return circuit
    }
}

extension PauliXGate : QuCircuitImplementable {
    public var circuitImplementation: QuCircuit {
        let circuit = QuCircuit(name: "|X|", numberOfInputs: 1)
        let h = HadamardGate()
        let z = PauliZGate()
        try! circuit.append(transformers: (transformer: h, time: 0, inputIndices:[0]),
                            (transformer: z, time: 1, inputIndices:[0]),
                            (transformer: h, time: 2, inputIndices:[0])
        )
        
        return circuit
    }
}

extension PauliZGate : QuCircuitImplementable {
    public var circuitImplementation: QuCircuit {
        let circuit = QuCircuit(name: "|Z|", numberOfInputs: 1)
        let h = HadamardGate()
        let x = PauliXGate()
        try! circuit.append(transformers: (transformer: h, time: 0, inputIndices:[0]),
                            (transformer: x, time: 1, inputIndices:[0]),
                            (transformer: h, time: 2, inputIndices:[0])
        )
        
        return circuit
    }
}
