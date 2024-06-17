//
//  AdditionCircuits.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 29/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

open class IncrementerCircuit : QuCircuit {
    public convenience init(modulus:Int) {
        let numberOfInputs = Int(ceil(log2(Double(modulus))))
        self.init(numberOfInputs: numberOfInputs)
    }
    
    public init(numberOfInputs:Int) {
        super.init(name: "|Inc-\(numberOfInputs)|", numberOfInputs: numberOfInputs)
        
        guard numberOfInputs > 1 else {
            try! self.append(transformer: QuNotGate(), atTime: 0, forInputAtIndex: 0)
            return
        }
        
        var time = 0
        for i in 0..<numberOfInputs-1 {
            let gate = MultiControlMultiTargetControlledGate(numberOfControlInputs: numberOfInputs-1-i, targetGate: QuNotGate())
            let gatePoints = Array((i..<numberOfInputs).reversed())
            try! self.append(transformer: gate, atTime: time, forInputAtIndices: gatePoints)
            
            time += 1
        }
        
        try! self.append(transformer: QuNotGate(), atTime: time, forInputAtIndex: numberOfInputs-1)
    }
    
    open func increment(_ register:QuRegister) throws -> QuRegister {
        let output = try self.transform(input: register)
        return try QuMeasurer(input: output).mostProbableRegisterOutput()
    }
    
    public required init() {
        super.init()
    }
}

open class DecrementerCircuit : QuCircuit {
    public init(numberOfInputs:Int) {
        let circuit = !IncrementerCircuit(numberOfInputs: numberOfInputs)
        super.init(name: "|Dec-\(numberOfInputs)|", numberOfInputs: numberOfInputs)
        
        self.timeline = circuit.timeline
    }
    
    public init(modulus:Int) {
        let circuit = !IncrementerCircuit(modulus: modulus)
        let numberOfInputs = circuit.numberOfInputs
        super.init(name: "|Dec-\(numberOfInputs)|", numberOfInputs: numberOfInputs)
        
        self.timeline = circuit.timeline
    }
    
    open func decrement(_ register:QuRegister) throws -> QuRegister {
        let output = try self.transform(input: register)
        return try QuMeasurer(input: output).mostProbableRegisterOutput()
    }
    
    public required init() {
        super.init()
    }
}

open class HalfTwoQuBitsAdderCircuit : QuCircuit {
    public required init() {
        super.init(name: "|Half2Adder|", numberOfInputs: 3)
        
        try! self.append(transformer: ToffoliCCNotGate(), atTime: 0, forInputAtIndices: [0, 1, 2])
        try! self.append(transformer: ControlledNotGate(), atTime: 1, forInputAtIndices: [0, 1])
    }
    
    public override init(name: String, numberOfInputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    public override init(name: String, numberOfInputs: Int, numberOfOutputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    open func add(first:QuBit, second:QuBit) -> (result:QuBit, carry:QuBit) {
        let matrix = try! self.transform(input: QuRegister(quBits: first, second, .grounded))
        let qubits = try! QuMeasurer(input: matrix).mostProbableQuBits().quBits
        
        return (qubits[1], qubits[2])
    }
}

open class HalfTwoQuBitsSubtractorCircuit : QuCircuit {
    public required init() {
        super.init(name: "|Half2Sub|", numberOfInputs: 3)
        
        let x = PauliXGate()
        
        try! self.append(transformer: ControlledNotGate(), atTime: 0, forInputAtIndices: [0, 1])
        try! self.append(transformer: x, atTime: 1, forInputAtIndex: 0)
        try! self.append(transformer: ToffoliCCNotGate(), atTime: 2, forInputAtIndices: [0, 1, 2])
        try! self.append(transformer: x, atTime: 3, forInputAtIndex: 0) //make the circuit reversible
    }
    
    public override init(name: String, numberOfInputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    public override init(name: String, numberOfInputs: Int, numberOfOutputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    open func subtract(first:QuBit, second:QuBit) -> (result:QuBit, borrow:QuBit) {
        let matrix = try! self.transform(input: QuRegister(quBits: first, second, .grounded))
        let qubits = try! QuMeasurer(input: matrix).mostProbableQuBits().quBits
        
        return (qubits[1], qubits[2])
    }
}

open class FullTwoQuBitsAdderCircuit : QuCircuit {
    public required init() {
        super.init(name: "|Full2Adder|", numberOfInputs: 4)
        
        let tof = ToffoliCCNotGate()
        let cnot = ControlledNotGate()
        try! self.append(transformer: tof, atTime: 0, forInputAtIndices: [1, 2, 3])
        try! self.append(transformer: cnot, atTime: 1, forInputAtIndices: [1, 2])
        try! self.append(transformer: tof, atTime: 2, forInputAtIndices: [0, 2, 3])
        try! self.append(transformer: cnot, atTime: 3, forInputAtIndices: [0, 2])
    }
    
    public override init(name: String, numberOfInputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    public override init(name: String, numberOfInputs: Int, numberOfOutputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    open func add(first:QuBit, second:QuBit, carry:QuBit) -> (result:QuBit, carry:QuBit) {
        let matrix = try! self.transform(input: QuRegister(quBits: first, second, carry, .grounded))
        let qubits = try! QuMeasurer(input: matrix).mostProbableQuBits().quBits
        
        return (qubits[2], qubits[3])
    }
}

open class FullTwoQuBitsSubtractorCircuit : QuCircuit {
    public required init() {
        super.init(name: "|Full2Sub|", numberOfInputs: 4)
        
        let subs = HalfTwoQuBitsSubtractorCircuit()
        
        try! self.append(transformer: subs, atTime: 0, forInputAtIndices: [0, 1, 3])
        try! self.append(transformer: subs, atTime: 1, forInputAtIndices: [1, 2, 3])
    }
    
    public override init(name: String, numberOfInputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    public override init(name: String, numberOfInputs: Int, numberOfOutputs: Int) {
        fatalError("You must use the init() constructor for this circuit")
    }
    
    open func subtract(first:QuBit, second:QuBit, borrow:QuBit) -> (result:QuBit, borrow:QuBit) {
        let matrix = try! self.transform(input: QuRegister(quBits: first, second, borrow, .grounded))
        let qubits = try! QuMeasurer(input: matrix).mostProbableQuBits().quBits
        
        return (qubits[2], qubits[3])
    }
}

open class AdderCircuit : QuCircuit {
    public convenience init(modulus:Int) {
        let numberOfInputs = (Int(ceil(log2(Double(modulus))))*3)+1 //we need extra qubits to store the carry & the sum
        self.init(numberOfInputs: numberOfInputs)
    }
    
    public init(numberOfInputs:Int) {
        let registerSize = (numberOfInputs-1)/3
        super.init(name: "|Adder-\(registerSize)|", numberOfInputs: numberOfInputs)
        
        var time = 0
        let gate = FullTwoQuBitsAdderCircuit()
        for i in 0..<registerSize {
            try! self.append(transformer: gate, atTime: time, forInputAtIndices: [i, i + registerSize, i + (registerSize*2), numberOfInputs-1])
            
            time += 1
        }
    }
    
    open func add(first:QuRegister, second:QuRegister, carry:QuBit) throws -> (result:QuRegister, carry:QuBit) {
        let qubits = first.quBits+second.quBits+([QuBit](repeating: .grounded, count: first.count))+[carry]
        let matrix = try self.transform(input: QuRegister(quBits: qubits))
        let allResultQuBits = try! QuMeasurer(input: matrix).mostProbableQuBits().quBits
        let resultQuBits = Array(allResultQuBits[(first.count*2)..<(first.count*3)])
        let carry = allResultQuBits[numberOfInputs-1]
        
        return (QuRegister(quBits: resultQuBits), carry)
    }
    
    public required init() {
        super.init()
    }
}

open class SubtractorCircuit : QuCircuit {
    public convenience init(modulus:Int) {
        let numberOfInputs = (Int(ceil(log2(Double(modulus))))*3)+1 //we need extra qubits to store the borrow & the subtraction
        self.init(numberOfInputs: numberOfInputs)
    }
    
    public init(numberOfInputs:Int) {
        let registerSize = (numberOfInputs-1)/3
        super.init(name: "|Sub-\(registerSize)|", numberOfInputs: numberOfInputs)
        
        var time = 0
        let gate = FullTwoQuBitsSubtractorCircuit()
        for i in 0..<registerSize {
            try! self.append(transformer: gate, atTime: time, forInputAtIndices: [i, i + registerSize, i + (registerSize*2), numberOfInputs-1])
            
            time += 1
        }
    }
    
    open func subtract(first:QuRegister, second:QuRegister, borrow:QuBit) throws -> (result:QuRegister, borrow:QuBit) {
        let qubits = first.quBits+second.quBits+([QuBit](repeating: .grounded, count: first.count))+[borrow]
        let matrix = try self.transform(input: QuRegister(quBits: qubits))
        let allResultQuBits = try! QuMeasurer(input: matrix).mostProbableQuBits().quBits
        let resultQuBits = Array(allResultQuBits[(first.count*2)..<(first.count*3)])
        let carry = allResultQuBits[numberOfInputs-1]
        
        return (QuRegister(quBits: resultQuBits), carry)
    }
    
    public required init() {
        super.init()
    }
}
