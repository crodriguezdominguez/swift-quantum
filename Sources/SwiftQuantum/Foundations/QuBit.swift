//
//  QuBit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 30/6/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation
import RealModule
import ComplexModule

public enum QuBitState {
    case grounded(Double)
    case excited(Double)
    case undefined
    
    var probability:Double? {
        switch self {
        case .grounded(let x):
            return x
        case .excited(let x):
            return x
        default:
            return nil
        }
    }
}

public typealias QuAmplitude = Complex<Double>

public struct QuBit : CustomStringConvertible, Equatable, QuAmplitudeMatrixConvertible {
    public fileprivate(set) var groundAmplitude: QuAmplitude
    public fileprivate(set) var excitedAmplitude: QuAmplitude
    
    public static let grounded:QuBit = QuBit(groundAmplitude: .one, excitedAmplitude: .zero)
    public static let excited:QuBit = QuBit(groundAmplitude: .zero, excitedAmplitude: .one)
    
    public init(grounded:Bool=true) {
        if grounded {
            groundAmplitude = .one
            excitedAmplitude = .zero
        }
        else{
            groundAmplitude = .zero
            excitedAmplitude = .one

        }
    }
    
    public init(groundAmplitude:QuAmplitude, excitedAmplitude:QuAmplitude) {
        self.groundAmplitude = groundAmplitude
        self.excitedAmplitude = excitedAmplitude
    }
    
    public init?(matrix:QuAmplitudeMatrix) {
        var mat = matrix
        if matrix.rows < matrix.columns {
            mat = transpose(matrix)
        }
        
        guard mat.rows == 2 && mat.columns == 1 else {
            return nil
        }
        
        self.groundAmplitude = mat[0, 0]
        self.excitedAmplitude = mat[1, 0]
    }
    
    public var groundStateProbability : Double {
        let groundAbs = groundAmplitude.abs
        let result = groundAbs * groundAbs
        if result =~ 1.0 {
            return 1.0
        }
        else if result =~ 0.0 {
            return 0.0
        }
        else {
            return result
        }
    }
    
    public var excitedStateProbability : Double {
        let excitedAbs = excitedAmplitude.abs
        let result = excitedAbs * excitedAbs
        if result =~ 1.0 {
            return 1.0
        }
        else if result =~ 0.0 {
            return 0.0
        }
        else {
            return result
        }
    }
    
    public var isNormalized:Bool {
        let absExcited = excitedAmplitude.abs
        let absGround = groundAmplitude.abs
        
        if (absExcited =~ 1.0) && (absGround =~ 0.0) {
            return true
        }
        else if (absGround =~ 1.0) && (absExcited =~ 0.0) {
            return true
        }
        
        return (groundStateProbability + excitedStateProbability) =~ 1.0
    }
    
    internal func inmutableMeasure() -> QuBitState {
        if !isNormalized {
            return .undefined
        }
        
        let absExcited = excitedAmplitude.abs
        let absGround = groundAmplitude.abs
        
        if (abs(absExcited) =~ 1.0) && (abs(absGround) =~ 0.0) {
            return .excited(1.0)
        }
        else if (abs(absGround) =~ 1.0) && (abs(absExcited) =~ 0.0) {
            return .grounded(1.0)
        }
        
        let groundProbability = groundStateProbability
        let excitedProbability = excitedStateProbability
        
        if groundProbability =~ 1.0 {
            return .grounded(1.0)
        }
        else if excitedProbability =~ 1.0 {
            return .excited(1.0)
        }
        
        let random = Double.random(in: 0..<1.0)
        
        if groundProbability =~ excitedProbability {
            if random < 0.5 {
                return .grounded(groundProbability)
            }
            else{
                return .excited(excitedProbability)
            }
        }
        
        if random < groundProbability {
            return .grounded(groundProbability)
        }
        else {
            return .excited(excitedProbability)
        }
    }
    
    public mutating func measure() -> QuBitState {
        let result = inmutableMeasure()
        switch result {
        case .excited:
            groundAmplitude = .zero
            excitedAmplitude = .one
        case .grounded:
            groundAmplitude = .one
            excitedAmplitude = .zero
        case .undefined:
            break
        }
        return result
    }
    
    public var description: String{
        var result = ""
        
        var sign = " + "
        if groundAmplitude == .one {
            result += "|0〉"
        }
        else if groundAmplitude != .zero {
            result += "\(groundAmplitude.arithmeticDescription)|0〉"
        }
        else{
            sign = ""
        }
        
        if excitedAmplitude == .one {
            result += "\(sign)|1〉"
        }
        else if excitedAmplitude != .zero {
            var excitedDescription = excitedAmplitude.arithmeticDescription
            if excitedDescription.hasPrefix("-") && !result.isEmpty {
                excitedDescription = excitedDescription.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                sign = " - "
            }
            
            result += "\(sign)\(excitedDescription)|1〉"
        }
        
        return result
    }
    
    public func matrixRepresentation() -> QuAmplitudeMatrix {
        var result = QuAmplitudeMatrix(rows: 2, columns: 1, repeatedValue: QuAmplitude(0.0, 0.0))
        result[0, 0] = self.groundAmplitude
        result[1, 0] = self.excitedAmplitude
        
        return result
    }
    
    public static func matrixRepresentation(of quBits:QuBit...) -> QuAmplitudeMatrix {
        let register = QuRegister(quBits: quBits)
        return register.matrixRepresentation()
    }
    
    public static func matrixRepresentation(of quBits:[QuBit]) -> QuAmplitudeMatrix {
        let register = QuRegister(quBits: quBits)
        return register.matrixRepresentation()
    }
}

public func ==(left:QuBit, right:QuBit) -> Bool {
    return (left.groundAmplitude.abs =~ right.groundAmplitude.abs) && (left.excitedAmplitude.abs =~ right.excitedAmplitude.abs)
}
