//
//  QuBitTransformer.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 3/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public protocol QuBitTransformer : CustomStringConvertible {
    var transformerName:String {get}
    var transformationMatrix:QuAmplitudeMatrix {get}
    var numberOfInputs:Int{get}
    var numberOfOutputs:Int{get} //to support multiplexers and coders
    
    init()
}

extension QuBitTransformer {
    public func transform(input:QuAmplitudeMatrixConvertible) throws -> QuAmplitudeMatrix {
        return try self.transform(input: input.matrixRepresentation())
    }
    
    public func transform(input:QuAmplitudeMatrix) throws -> QuAmplitudeMatrix {
        return try self.transformationMatrix*input
    }
    
    public var description:String {
        return self.transformerName
    }
}

func ==<T : QuBitTransformer>(left:T, right:T) -> Bool {
    return left.transformerName == right.transformerName
}

public protocol UnaryQuBitTransformer : QuBitTransformer {
    
}

public protocol BinaryQuBitTransformer : QuBitTransformer {
    
}

public protocol TernaryQuBitTransformer : QuBitTransformer {
    
}

public protocol MultipleQuBitTransformer : QuBitTransformer {
    
}

extension UnaryQuBitTransformer {
    public var numberOfInputs:Int{
        return 1
    }
    public var numberOfOutputs:Int{
        return 1
    }
    
    public func transform(input:QuBit) -> QuBit {
        let representation = try! self.transform(input: input.matrixRepresentation())
        return QuBit(matrix: representation)!
    }
}

extension BinaryQuBitTransformer {
    public var numberOfInputs:Int{
        return 2
    }
    public var numberOfOutputs:Int{
        return 2
    }
    
    public func transform(input:(QuBit, QuBit)) -> QuAmplitudeMatrix {
        let input = QuBit.matrixRepresentation(of: input.0, input.1)
        return try! self.transform(input: input)
    }
}

extension TernaryQuBitTransformer {
    public var numberOfInputs:Int{
        return 3
    }
    public var numberOfOutputs:Int{
        return 3
    }
    
    public func transform(input:(QuBit, QuBit, QuBit)) -> QuAmplitudeMatrix {
        let input = QuBit.matrixRepresentation(of: input.0, input.1, input.2)
        return try! self.transform(input: input)
    }
}

public protocol QuBitParameterizedTransformer : QuBitTransformer {
    associatedtype ParameterType
    var parameter:ParameterType {get}
    init(parameter:ParameterType)
}

public extension QuBitParameterizedTransformer {
    init() {
        fatalError("You must use the init(parameter:) initializer")
    }
}

extension QuBitParameterizedTransformer where ParameterType : RealType {
    var parameterStringRepresentation:String {
        return String(format: "%.2f", Double(parameter))
    }
}
