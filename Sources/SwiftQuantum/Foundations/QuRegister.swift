//
//  QuRegister.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 30/6/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//


import Foundation

public struct QuRegister : MutableCollection, CustomStringConvertible, QuAmplitudeMatrixConvertible {
    
    public typealias Index = Int
    public typealias Element = QuBit
    
    public subscript(position: Int) -> QuBit {
        get {
            return quBits[position]
        }
        set(newValue) {
            quBits[position] = newValue
        }
    }
    
    public func index(after i: Int) -> Int {
        return i+1
    }

    public internal(set) var quBits:[QuBit]
    
    public var startIndex: Int {
        return quBits.startIndex
    }
    
    public var endIndex: Int {
        return quBits.endIndex
    }
    
    public init(fromNumber number:UInt32) {
        quBits = []
        var size:Int
        if number == 0 {
            size = 1
        }
        else{
            size = Int(log2(Double(number))+0.5)
        }
        
        let binary = number.binaryRepresentation(numberOfBits: size)
        for character in binary {
            if character == "0" {
                quBits.append(.grounded)
            }
            else{
                quBits.append(.excited)
            }
        }
    }
    
    public init(fromNumber number:UInt32, minNumberOfQuBits:Int) {
        quBits = []
        var size:Int
        if number == 0 {
            size = 1
        }
        else{
            size = Int(log2(Double(number))+0.5)
        }
        
        let binary = number.binaryRepresentation(numberOfBits: Swift.max(size, minNumberOfQuBits))
        for character in binary {
            if character == "0" {
                quBits.append(.grounded)
            }
            else{
                quBits.append(.excited)
            }
        }
    }
    
    public init(quBits:QuBit...) {
        self.quBits = quBits
    }
    
    public init(quBits:[QuBit]) {
        self.quBits = quBits
    }
    
    public init(numberOfQuBits nqubits:Int) {
        self.quBits = []
        for _ in 0..<nqubits {
            self.quBits.append(QuBit.grounded)
        }
    }
    
    public var countCodifiedStates:UInt64 {
        return UInt64(pow(2.0, Double(quBits.count)))
    }
    
    public var description: String {
        var result = ""
        for k in 0..<countCodifiedStates {
            let amplitude = self.amplitude(forStateNumber: k)
            let abs = amplitude.abs
            if abs > Double.ulpOfOne {
                if (abs - 1.0) <= Double.ulpOfOne {
                    result += "|\(k.binaryRepresentation(numberOfBits: self.quBits.count))〉\n"
                }
                else{
                    result += "\(amplitude)|\(k.binaryRepresentation(numberOfBits: self.quBits.count))〉\n"
                }
            }
        }
        
        return result
    }
    
    public func amplitude(forStateNumber index:UInt64) -> QuAmplitude {
        var amplitude = QuAmplitude.one
        for (idx, quBit) in self.quBits.enumerated() {
            amplitude *= self.amplitude(of: quBit, atIndex: idx, forPosition: UInt(index))
        }
        
        return amplitude
    }
    
    public func matrixRepresentation() -> QuAmplitudeMatrix {
        var result = self.quBits.first!.matrixRepresentation()
        
        for (idx, quBit) in self.quBits.enumerated() {
            guard idx > 0 else {
                continue
            }
            
            result = tensorProduct(result, quBit.matrixRepresentation())
        }
        
        return result
    }
    
    public func measure() -> [String:Double] {
        var coherentState = true
        var coherenceBinary = ""
        for quBit in quBits {
            if quBit.groundAmplitude != .one && quBit.excitedAmplitude != .one {
                coherentState = false
                break
            }
            if case .excited(1.0) = quBit.inmutableMeasure() {
                coherenceBinary += "1"
            }
            else if case .grounded(1.0) = quBit.inmutableMeasure() {
                coherenceBinary += "0"
            }
        }
        
        if coherentState {
            return [coherenceBinary : 1.0]
        }
        
        return QuMeasurer(input: self).probabilisticMap()
    }
    
    public func mostProbableIntegerValue() -> UInt32 {
        let measurements = self.measure()
        var selectedKey = ""
        var maxValue = -Double.infinity
        
        for (key, value) in measurements {
            if value > maxValue {
                selectedKey = key
                maxValue = value
            }
        }
        
        var equalValues = [String]()
        for (key, value) in measurements {
            if value == maxValue {
                equalValues.append(key)
            }
        }
        
        selectedKey = equalValues[Int.random(in: 0..<equalValues.count)]
        
        //var result:UInt32 = 0
        let allCharacters = selectedKey.reversed()
        let result = allCharacters.enumerated().reduce(UInt32(0)) {(result, values) in
            if values.element == "1" {
                return result + UInt32(pow(2.0, Double(values.offset)))
            }
            else {
                return result
            }
        }
        
        return result
    }
    
    public func makeIterator() -> AnyIterator<QuBit> {
        var k:Int = 0
        
        return AnyIterator{
            guard k < self.count else {
                return nil
            }
            
            let result = self.quBits[k]
            k += 1
            
            return result
        }
    }
    
    public func transformed(using circuit:QuCircuit) throws -> QuRegister {
        let matrix = try circuit.transform(input: self)
        let measurer = try QuMeasurer(input: matrix)
        let register = QuRegister(fromNumber: measurer.mostProbableIntegerValue().integer)
        
        return register
    }
    
    public mutating func transform(using circuit:QuCircuit) throws {
        self = try self.transformed(using: circuit)
    }
    
    public func amplitude(of quBit:QuBit, atIndex index:Int, forPosition position:UInt) -> QuAmplitude {
        let binary = position.binaryRepresentation(numberOfBits: self.quBits.count)
        if index >= binary.count {
            return quBit.groundAmplitude
        }
        else if binary[binary.index(binary.startIndex, offsetBy: index)] == "0" {
            return quBit.groundAmplitude
        }
        else{
            return quBit.excitedAmplitude
        }
    }
    
    public func append(_ register:QuRegister) -> QuRegister {
        return QuRegister(quBits: self.quBits+register.quBits)
    }
    
    public var count: Int {
        return self.quBits.count
    }
}

extension UnaryQuBitTransformer {
    public func transform(input:QuRegister) -> QuRegister {
        let quBits = input.quBits.map{try! QuBit(matrix: self.transform(input: $0.matrixRepresentation()))!}
        
        return QuRegister(quBits: quBits)
    }
}
