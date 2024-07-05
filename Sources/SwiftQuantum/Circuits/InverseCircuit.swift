//
//  InverseCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 30/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public struct InverseCircuit : QuCircuitRepresentable {
    public private(set) var quCircuit: QuCircuit
    
    public init(of input: any QuCircuitRepresentable) {
        let trimmedString = input.quCircuit.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        
        quCircuit = QuCircuit(name: "|Inv\(trimmedString)|", numberOfInputs: input.numberOfInputs)
        
        let maxTime = input.quCircuit.timeline.keys.max()!
        var newTimeline = input.quCircuit.timeline
        
        for key in input.quCircuit.timeline.keys {
            let newKey = maxTime-key
            newTimeline[newKey] = input.quCircuit.timeline[key]
        }
        
        quCircuit.timeline = newTimeline
    }
}

public prefix func !(circuit: any QuCircuitRepresentable) -> some QuCircuitRepresentable {
    return InverseCircuit(of: circuit)
}
