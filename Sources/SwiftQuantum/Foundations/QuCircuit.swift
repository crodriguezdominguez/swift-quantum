//
//  QuCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 2/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public protocol QuCircuitRepresentable: CustomStringConvertible, Equatable, MultipleQuBitTransformer {
    var quCircuit: QuCircuit {get}
}

public extension QuCircuitRepresentable {
    var transformerName: String {
        return quCircuit.transformerName
    }
    
    var description: String {
        return quCircuit.description
    }
    
    var numberOfInputs: Int {
        return self.quCircuit.numberOfInputs
    }
    
    var transformationMatrix: QuAmplitudeMatrix {
        return self.quCircuit.transformationMatrix
    }
    
    var numberOfOutputs: Int {
        numberOfInputs
    }
    
    init() {
        fatalError("init() constructor can not be used in circuits")
    }
}

public struct QuCircuit : QuCircuitRepresentable {
    private class CacheAmplitudeMatrix {
        var matrix: QuAmplitudeMatrix?
        
        init(matrix: QuAmplitudeMatrix?) {
            self.matrix = matrix
        }
    }
    
    public internal(set) var timeline:[Int:[(transformer:QuBitTransformer, indices:[Int])]] = [:]
    public var transformerName:String
    public fileprivate(set) var numberOfInputs:Int
    
    private let cacheAmplitudeMatrix = CacheAmplitudeMatrix(matrix: nil)
        
    public var quCircuit: QuCircuit {
        return self
    }
    
    public var transformationMatrix: QuAmplitudeMatrix {
        if let matrix = cacheAmplitudeMatrix.matrix {
            return matrix
        }
        
        cacheAmplitudeMatrix.matrix = calculateTransformationMatrix()
        
        return cacheAmplitudeMatrix.matrix!
    }
    
    public init(name:String, numberOfInputs:Int) {
        self.transformerName = name
        self.numberOfInputs = numberOfInputs
    }
    
    public init(from representable: any QuCircuitRepresentable) {
        let circuit = representable.quCircuit
        self.transformerName = circuit.transformerName
        self.numberOfInputs = circuit.numberOfInputs
        self.timeline = circuit.timeline
        self.cacheAmplitudeMatrix.matrix = circuit.cacheAmplitudeMatrix.matrix
    }
    
    fileprivate func calculateTransformationMatrix() -> QuAmplitudeMatrix {
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
        
        return x.compressed()
    }
    
    public var countGates:Int {
        return timeline.reduce(0) { (result, entry) in
            result+entry.1.count
        }
    }
    
    fileprivate mutating func invalidateCacheTransformationMatrix() {
        self.cacheAmplitudeMatrix.matrix = nil
    }
    
    public mutating func clear() {
        self.numberOfInputs = 1
        self.timeline = [:]
    }
    
    public mutating func clearGates(input: Int) {
        for (key, entries) in timeline {
            let newEntries = entries.filter { (_, indices) in
                !indices.contains{ $0 == input }
            }
            if newEntries.isEmpty {
                timeline.removeValue(forKey: key)
            } else {
                timeline[key] = newEntries
            }
        }
    }
    
    public mutating func replaceWithContents(of circuit: QuCircuit) {
        self.timeline = circuit.timeline
        self.transformerName = circuit.transformerName
        self.numberOfInputs = circuit.numberOfInputs
    }
    
    public mutating func appendNewInput(transformer: UnaryQuBitTransformer) throws {
        self.numberOfInputs += 1
        try self.append(transformer: transformer, atTime: 0, forInputAtIndex: self.numberOfInputs-1)
    }
    
    public mutating func append(transformers: (transformer:QuBitTransformer, time:Int, inputIndices:[Int])...) throws {
        for entry in transformers {
            try self.append(transformer: entry.transformer, atTime: entry.time, forInputAtIndices: entry.inputIndices)
        }
        
        self.invalidateCacheTransformationMatrix()
    }
    
    public mutating func append(transformer:UnaryQuBitTransformer, atTime time:Int, forInputAtIndex index:Int) throws {
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
        
        self.invalidateCacheTransformationMatrix()
    }
    
    public mutating func append(transformer:QuBitTransformer, atTime time:Int, forInputAtIndices indices:[Int]) throws {
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
        
       self.invalidateCacheTransformationMatrix()
    }
    
    public mutating func remove(fromTime time:Int, atIndex index: Int) {
        if let entries = self.timeline[time] {
            var entries = entries
            entries.remove(at: index)
            self.timeline[time] = entries
        }
        
        self.invalidateCacheTransformationMatrix()
    }
    
    public mutating func remove(fromTime time:Int, usingInput input: Int) {
        if let entries = self.timeline[time] {
            let entries = entries.filter { (_, indices) in
                !indices.contains { $0 == input }
            }
            self.timeline[time] = entries
        }
        
        self.invalidateCacheTransformationMatrix()
    }
    
    public mutating func transform(input:QuRegister) throws -> QuAmplitudeMatrix {
        return try transform(input: input.matrixRepresentation())
    }
    
    public mutating func transform(input:QuAmplitudeMatrix) throws -> QuAmplitudeMatrix {
        return try self.transform(upToStep: self.timeline.count-1, forInput: input)
    }
    
    public func transform(upToStep maxStep:Int, forInput input:QuRegister) throws -> QuAmplitudeMatrix {
        return try self.transform(upToStep: maxStep, forInput: input.matrixRepresentation())
    }
    
    public func transform(_ fromStep:Int=0, upToStep maxStep:Int, forInput input:QuAmplitudeMatrix) throws -> QuAmplitudeMatrix {
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
    
    public var countTransformationSteps: Int {
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
    
    public var description: String {
        var result = "\(self.transformerName) (inputs/outputs: \(numberOfInputs)):\n"
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

public func ==(left: QuCircuit, right: QuCircuit) -> Bool {
    if left.transformerName == right.transformerName && left.numberOfInputs == right.numberOfInputs {
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

public func ==(left: any QuCircuitRepresentable, right: any QuCircuitRepresentable) -> Bool {
    return left.quCircuit == right.quCircuit
}

