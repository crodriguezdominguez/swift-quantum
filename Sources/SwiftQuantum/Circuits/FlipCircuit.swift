//
//  FlipCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 29/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

open class FlipCircuit : QuCircuit {
    public required init(numberOfInputs:Int) {
        super.init(name: "|Flip-\(numberOfInputs)|", numberOfInputs: numberOfInputs)
        
        let swap = SwapGate()
        for k in 0..<numberOfInputs/2 {
            try! self.append(transformer: swap, atTime: 0, forInputAtIndices: [k, numberOfInputs-k-1])
        }
    }
    
    public required init() {
        super.init()
    }
}
