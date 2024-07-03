//
//  QuCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 2/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

open class QuCircuit : CustomStringConvertible, Equatable, MultipleQuBitTransformer {
    open internal(set) var timeline:[Int:[(transformer:QuBitTransformer, indices:[Int])]] = [:]
    open var transformerName:String
    open fileprivate(set) var numberOfInputs:Int
    open fileprivate(set) var numberOfOutputs:Int
    
    fileprivate var _transformationMatrix: QuAmplitudeMatrix? = nil
    
    open var transformationMatrix: QuAmplitudeMatrix {
        if let tr = _transformationMatrix {
            return tr
        }
        
        let size = Int(pow(2.0, Double(numberOfInputs)))
        var x = QuAmplitudeMatrix.identity(size: size).uncompressed()
        let times = self.timeline.keys.sorted(by: <)
        
        for time in times {
            let entries = self.timeline[time]!
            for entry in entries {
                let (gate, indices) = entry
                let matrix = gate.transformationMatrix
                let result = expandMatrix(nqubits: numberOfInputs, matrix: matrix, indices: indices)
                x = try! result * x
            }
        }
        
        _transformationMatrix = x.compressed()
        
        return _transformationMatrix!
    }
    
    public required init() {
        fatalError("init() constructor can not be used in circuits")
    }
    
    public init(name:String, numberOfInputs:Int, numberOfOutputs:Int) {
        self.transformerName = name
        self.numberOfInputs = numberOfInputs
        self.numberOfOutputs = numberOfOutputs
    }
    
    public init(name:String, numberOfInputs:Int) {
        self.transformerName = name
        self.numberOfInputs = numberOfInputs
        self.numberOfOutputs = numberOfInputs
    }
    
    open var countGates:Int {
        return timeline.reduce(0) { (result, entry) in
            result+entry.1.count
        }
    }
    
    fileprivate func reloadCacheTransformationMatrix() {
        _transformationMatrix = nil
    }
    
    open func clearGates(input: Int) -> QuCircuit {
        self.timeline = self.timeline.filter { (_, entry) in
            !entry.contains { $0.indices.contains { $0 == input } }
        }
        return self
    }
    
    open func append(transformers: (transformer:QuBitTransformer, time:Int, inputIndices:[Int])...) throws {
        for entry in transformers {
            try self.append(transformer: entry.transformer, atTime: entry.time, forInputAtIndices: entry.inputIndices)
        }
        
        self.reloadCacheTransformationMatrix()
    }
    
    open func append(transformer:UnaryQuBitTransformer, atTime time:Int, forInputAtIndex index:Int) throws {
        guard index < self.numberOfInputs else {
            throw NSError(domain: "Quantum computing", code: 101, userInfo: [NSLocalizedDescriptionKey: "The input index is out of range: The circuit has a limit of \(self.numberOfInputs) inputs"])
        }
        
        let entry = (transformer: transformer as QuBitTransformer, indices: [index])
        if timeline[time] == nil {
            timeline[time] = [entry]
        }
        else{
            var newEntries = timeline[time]!
            newEntries.append(entry)
            timeline[time] = newEntries
        }
        
        self.reloadCacheTransformationMatrix()
    }
    
    open func append(transformer:QuBitTransformer, atTime time:Int, forInputAtIndices indices:[Int]) throws {
        guard indices.count == transformer.numberOfInputs else {
            throw NSError(domain: "Quantum computing", code: 100, userInfo: [NSLocalizedDescriptionKey: "The amount of inputs of the gate must be equal to the amount of provided indices"])
        }
        
        //sanity check
        for index in indices {
            if index >= self.numberOfInputs {
                throw NSError(domain: "Quantum computing", code: 101, userInfo: [NSLocalizedDescriptionKey: "The input index is out of range: The circuit has a limit of \(self.numberOfInputs) inputs"])
            }
        }
        
        let entry = (transformer: transformer, indices: indices)
        if timeline[time] == nil {
            timeline[time] = [entry]
        }
        else{
            var newEntries = timeline[time]!
            newEntries.append(entry)
            timeline[time] = newEntries
        }
        
       self.reloadCacheTransformationMatrix()
    }
    
    open func remove(fromTime time:Int, atIndex index:Int) {
        if let entries = self.timeline[time] {
            var entries = entries
            entries.remove(at: index)
            self.timeline[time] = entries
        }
        
        self.reloadCacheTransformationMatrix()
    }
    
    open func transform(input:QuRegister) throws -> QuAmplitudeMatrix {
        return try transform(input: input.matrixRepresentation())
    }
    
    open func transform(input:QuAmplitudeMatrix) throws -> QuAmplitudeMatrix {
        return try self.transform(upToStep: self.timeline.count-1, forInput: input)
    }
    
    open func transform(upToStep maxStep:Int, forInput input:QuRegister) throws -> QuAmplitudeMatrix {
        return try self.transform(upToStep: maxStep, forInput: input.matrixRepresentation())
    }
    
    open func transform(_ fromStep:Int=0, upToStep maxStep:Int, forInput input:QuAmplitudeMatrix) throws -> QuAmplitudeMatrix {
        let times = self.timeline.keys.sorted(by: <)
        var x = input.uncompressed()
        if x.rows < x.columns {
            x = transpose(x)
        }
        
        guard x.columns == 1 && x.rows % 2 == 0 else {
            throw NSError(domain: "Quantum computing", code: 103, userInfo: [NSLocalizedDescriptionKey: "The dimensions of the circuit input matrix must be 1xn or nx1, where n must be an even number"])
        }
        
        let nqubits = Int(log2(Double(x.rows)))
        
        guard self.numberOfInputs == nqubits else {
            throw NSError(domain: "Quantum computing", code: 102, userInfo: [NSLocalizedDescriptionKey: "The amount of qubits in the register must be equal to the number of expected inputs of the circuit"])
        }
        
        for (step, time) in times.enumerated() {
            guard step >= fromStep else {
                continue
            }
            
            guard step <= maxStep else {
                break
            }
            
            let entries = self.timeline[time]!
            for entry in entries {
                let (transformer, indices) = entry
                let matrix = transformer.transformationMatrix
                let result = expandMatrix(nqubits: nqubits, matrix: matrix, indices: indices)
                x = try result * x
            }
        }
        
        return x.compressed()
    }
    
    open var countTransformationSteps:Int {
        return self.timeline.count
    }
    
    /*
     Taken from Quantum Computer Simulation: A Genetic Programming Approach; Lee Spector; Springer, 1999.
    */
    fileprivate func expandMatrix(nqubits:Int, matrix G:QuAmplitudeMatrix, indices:[Int]) -> QuAmplitudeMatrix {
        var qubits = indices
        var _qubits = [Int]()
        let n = Int(pow(2.0, Double(nqubits)))
        for i in 0..<qubits.count {
            qubits[i] = (nqubits-1) - qubits[i]
        }
        
        qubits = qubits.reversed()
        for i in 0..<nqubits {
            if qubits.firstIndex(of: i) == nil {
                _qubits.append(i)
            }
        }
        
        var M = QuAmplitudeMatrix(rows: n, columns: n, repeatedValue: QuAmplitude(0.0, 0.0), compressed: false)
        for i in 0..<n {
            for j in 0..<n {
                var bitsEqual = true
                for k in 0..<_qubits.count {
                    if ((i & (1 << _qubits[k])) != (j & (1 << _qubits[k]))) {
                        bitsEqual = false
                        break
                    }
                }
                if (bitsEqual) {
                    var istar:UInt = 0, jstar:UInt = 0
                    for k in 0..<qubits.count {
                        let q = qubits[k]
                        let ui = UInt(i)
                        let uj = UInt(j)
                        let uq = UInt(q)
                        let uk = UInt(k)
                        
                        istar |= ((ui & (1 << uq)) >> uq) << uk
                        jstar |= ((uj & (1 << uq)) >> uq) << uk
                    }
                    
                    M[i, j] = G[Int(istar), Int(jstar)]
                }
            }
        }
        
        return M
    }
    
    internal func allTransformers() -> [QuBitTransformer] {
        var result = [QuBitTransformer]()
        for (_, entries) in self.timeline {
            for entry in entries {
                if let circuit = entry.transformer as? QuCircuit {
                    result += circuit.allTransformers()
                }
                else{
                    result.append(entry.transformer)
                }
            }
        }
        
        //remove duplicates
        result = result.reduce([QuBitTransformer]()) { (res, trans) in
            if res.contains(where: {$0.transformerName == trans.transformerName}) == false {
                return res + [trans]
            }
            return res
        }
        
        return result
    }
    
    open var description: String {
        var result = "\(self.transformerName) (inputs: \(numberOfInputs), outputs: \(numberOfOutputs)):\n"
        for time in self.timeline.keys.sorted(by: <) {
            let entries = self.timeline[time]!
            result += "\t\(time): "
            for entry in entries {
                result += "\(entry.transformer.transformerName)(\(entry.indices)), "
            }
            result += "\n"
        }
        result += "\n"
        
        return result
    }
}

public func ==(left:QuCircuit, right:QuCircuit) -> Bool {
    if left.transformerName == right.transformerName && left.numberOfInputs == right.numberOfInputs && left.numberOfOutputs == right.numberOfOutputs {
        let leftGrid = left.transformationMatrix.contents
        let rightGrid = right.transformationMatrix.contents
        
        for i in 0..<leftGrid.count {
            if leftGrid[i] !~ rightGrid[i] {
                return false
            }
        }
        
        return true
    }
    
    return false
}
