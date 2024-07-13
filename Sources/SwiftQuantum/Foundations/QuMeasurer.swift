//
//  QuProbabilisticMeasurer.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 4/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation
import ComplexModule

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


public struct QuMeasurer {
    fileprivate let input:QuAmplitudeMatrix
    
    public init(input:QuRegister) {
        try! self.init(input:input.matrixRepresentation())
    }
    
    public init(input:QuAmplitudeMatrix) throws {
        guard input.rows == 1 || input.columns == 1 else {
            throw NSError(domain: "Quantum Measurer", code: 100, userInfo: [NSLocalizedDescriptionKey: "Measurements can only be made on 1 row or 1 column matrices"])
        }
        
        self.input = input
    }
    
    public func probabilisticMap(includeImpossibleStates:Bool=false) -> [String:Double] {
        let size = max(input.rows, input.columns)
        var result = [String:Double]()
        let nqubits = Int(log2(Double(size)))
        let matrixRepresentation = input.contents
        for (idx, complex) in matrixRepresentation.enumerated() {
            let module = complex.abs
            let probability = module*module
            let key = "\(idx.binaryRepresentation(numberOfBits: nqubits))"
            if probability > 0.0 {
                if probability =~ 1.0 {
                    if !includeImpossibleStates {
                        return [key:1.0]
                    }
                    else {
                        result[key] = 1.0
                    }
                }
                else if probability !~ 0.0 {
                    result[key] = probability
                }
                else if includeImpossibleStates {
                    result[key] = 0.0
                }
            }
            else if includeImpossibleStates {
                result[key] = 0.0
            }
        }
        
        //avoid precision issues
        let assumeMaxProbValue = 0.999999999999 //good enough precision
        let assumeMinProbValue = 0.000000000001 //good enough precision
        
        if result.count == 1 && !includeImpossibleStates {
            let key = result.keys.first!
            if result[key] >= assumeMaxProbValue {
                result[key] = 1.0
            }
        }
        else if includeImpossibleStates {
            for (key, prob) in result {
                if prob >= assumeMaxProbValue && prob < 1.0 {
                    result[key] = 1.0
                }
                else if prob <= assumeMinProbValue && prob > 0.0 {
                    result[key] = 0.0
                }
            }
        }
        
        return result
    }
    
    public func mostProbableRegisterOutput() -> QuRegister {
        let quBits = self.mostProbableQuBits().quBits
        return QuRegister(quBits: quBits)
    }
    
    public func mostProbableQuBits() -> (quBits:[QuBit], probability:Double) {
        let (states, prob) = mostProbableStates()
        
        var result:[QuBit] = []
        for state in states.reversed() {
            if case .excited(_) = state {
                result.append(.excited)
            }
            else{
                result.append(.grounded)
            }
        }
        
        return (result, prob)
    }
    
    public func mostProbableStates() -> (states:[QuBitState], probability:Double) {
        let measurements = probabilisticMap()
        var possibleValues = [String]()
        
        var maxValue = -Double.infinity
        for value in measurements.values {
            if value > maxValue {
                maxValue = value
            }
        }
        
        for (key, value) in measurements {
            if value =~ maxValue {
                possibleValues.append(key)
            }
        }
        
        let selectedKey = possibleValues[Int(arc4random_uniform(UInt32(possibleValues.count)))]
        
        var result:[QuBitState] = []
        for (idx, character) in selectedKey.reversed().enumerated() {
            let probability = self.calculateProbability(of: character, at: idx, in: measurements)
            if character == "1" {
                result.append(.excited(probability))
            }
            else{
                result.append(.grounded(probability))
            }
        }
        
        return (result, maxValue)
    }
    
    public func mostProbableState(ofQuBitAtIndex index:Int) -> QuBitState {
        let measurements = probabilisticMap()
        var possibleValues = [String]()
        
        var maxValue = -Double.infinity
        for value in measurements.values {
            if value > maxValue {
                maxValue = value
            }
        }
        
        for (key, value) in measurements {
            if value =~ maxValue {
                possibleValues.append(key)
            }
        }
        
        let selectedKey = possibleValues[Int(arc4random_uniform(UInt32(possibleValues.count)))]
        let character = selectedKey.reversed()[index]
        let probability = self.calculateProbability(of: character, at: index, in: measurements)
        if character == "1" {
            return .excited(probability)
        }
        else{
            return .grounded(probability)
        }
    }
    
    public func entangledQuBits() -> [QuBit] {
        let nqubits = Int(log2(Double(self.input.rows)))
        var result = [QuBit](repeating: .grounded, count: nqubits)
        for qubit in 0..<nqubits {
            var alpha = QuAmplitude(0.0, 0.0)
            var beta = QuAmplitude(0.0, 0.0)
            for (idx, value) in self.input.enumerated() {
                let binary = "\(idx.binaryRepresentation(numberOfBits: nqubits))"
                if binary[binary.index(binary.startIndex, offsetBy: qubit)] == "0" {
                    alpha += value.first!
                }
                else {
                    beta += value.first!
                }
            }
            
            let frac = sqrt(pow(alpha.abs, 2.0)+pow(beta.abs, 2.0))
            if frac == 0.0 {
                result[qubit] = QuBit(groundAmplitude: Complex(0.5.squareRoot(), 0.0), excitedAmplitude: Complex(0.5.squareRoot(), 0.0))
            }
            else {
                result[qubit] = QuBit(groundAmplitude: alpha/frac, excitedAmplitude: beta/frac)
            }
        }
        
        return result
    }
    
    fileprivate func calculateProbability(of character:Character, at index:Int, in probabilisticMap:[String:Double]) -> Double {
        var probability = 0.0
        
        for (key, prob) in probabilisticMap {
            if key[key.index(key.startIndex, offsetBy: index)] == character {
                probability += prob
            }
        }
        
        return probability
    }
    
    public func amplitudesMap() -> [(state:String, amplitude:QuAmplitude, probability:Double)] {
        let map = self.probabilisticMap()
        let matrixRepresentation = input.contents
        let nqubits = map.keys.first!.count
        var posibilities:[(state:String, amplitude:QuAmplitude,probability:Double)] = []
        for (idx, complex) in matrixRepresentation.enumerated() {
            let key = "\(idx.binaryRepresentation(numberOfBits: nqubits))"
            if let prob = map[key] {
                posibilities.append((key, complex, prob))
            }
        }
        
        return posibilities
    }
    
    public func mostProbableAmplitude() -> (state:String, amplitude:QuAmplitude, probability:Double) {
        return self.amplitudesMap().max{ first, second in first.probability > second.probability }!
    }
    
    public func mostProbableIntegerValue() -> (integer:UInt32, probability:Double) {
        let (states, prob) = mostProbableStates()
        
        let result = states.enumerated().reduce(UInt32(0)) { (result, values) in
            if case .excited(_) = values.element {
                return result + UInt32(pow(2.0, Double(values.offset)))
            }
            else{
                return result
            }
        }
        
        return (result, prob)
    }
}
