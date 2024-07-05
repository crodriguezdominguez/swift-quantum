//
//  FlipCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 29/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public struct FlipCircuit: QuCircuitRepresentable {
    public private(set) var quCircuit: QuCircuit
    
    public init(numberOfInputs:Int) {
        quCircuit = QuCircuit(name: "|Flip-\(numberOfInputs)|", numberOfInputs: numberOfInputs)
        
        let swap = SwapGate()
        for k in 0..<numberOfInputs/2 {
            try! quCircuit.append(transformer: swap, atTime: 0, forInputAtIndices: [k, numberOfInputs-k-1])
        }
    }
}
