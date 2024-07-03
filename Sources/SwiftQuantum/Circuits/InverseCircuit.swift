//
//  InverseCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 30/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

open class InverseCircuit : QuCircuit {
    public init(of circuit:QuCircuit) {
        let trimmedString = circuit.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        
        super.init(name: "|Inv\(trimmedString)|", numberOfInputs: circuit.numberOfInputs)
        
        let maxTime = circuit.timeline.keys.max()!
        var newTimeline = circuit.timeline
        
        for key in circuit.timeline.keys {
            let newKey = maxTime-key
            newTimeline[newKey] = circuit.timeline[key]
        }
        
        self.timeline = newTimeline
    }
    
    public required init() {
        super.init()
    }
}

public prefix func !(circuit:QuCircuit) -> QuCircuit {
    return InverseCircuit(of: circuit)
}
