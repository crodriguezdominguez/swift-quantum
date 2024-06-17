//
//  QuGate.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 30/6/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public struct HadamardGate : UnaryQuBitTransformer {
    public let transformerName: String = "|H|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        let root = QuAmplitude(0.5.squareRoot(), 0)
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: root)
        matrix[1, 1] = -root
        
        transformationMatrix = matrix
    }
}

extension QuRegister {
    public init(hadamardForNumberOfQuBits nqubits:Int) {
        self.quBits = []
        
        for _ in 0..<nqubits {
            let output = HadamardGate().transform(input: .grounded)
            self.quBits.append(output)
        }
    }
}

public struct SquareRootOfNotGate : UnaryQuBitTransformer {
    public let transformerName: String = "|√NOT|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        let root = QuAmplitude(0.5.squareRoot(), 0)
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: root)
        matrix[0, 1] = -root
        
        transformationMatrix = matrix
    }
}

public struct PauliXGate : UnaryQuBitTransformer {
    public let transformerName: String = "|X|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        matrix[0, 1] = one
        matrix[1, 0] = one
        
        transformationMatrix = matrix
    }
}

typealias QuNotGate = PauliXGate

public struct PauliYGate : UnaryQuBitTransformer {
    public let transformerName: String = "|Y|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: 0.0)
        matrix[0, 1] = -1.0.i
        matrix[1, 0] = 1.0.i
        
        self.transformationMatrix = matrix
    }
}

public struct PauliZGate : UnaryQuBitTransformer {
    public let transformerName: String = "|Z|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: 0.0)
        matrix[0, 0] = QuAmplitude(1.0, 0.0)
        matrix[1, 1] = QuAmplitude(-1.0, 0.0)
        
        transformationMatrix = matrix
    }
}

public struct PhaseShiftGate : UnaryQuBitTransformer, QuBitParameterizedTransformer {
    public var transformerName: String {
        return "|PhShift \(self.parameterStringRepresentation)|"
    }
    
    public let transformationMatrix: QuAmplitudeMatrix
    public let parameter:Double
    
    public init(parameter:Double) {
        self.parameter = parameter
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: 0.0)
        matrix[0, 0] = QuAmplitude(1.0, 0.0)
        matrix[1, 1] = pow(M_E, self.parameter.i)
        
        self.transformationMatrix = matrix
    }
}

public struct PhaseGate : UnaryQuBitTransformer, QuBitParameterizedTransformer {
    public var transformerName: String {
        return "|Ph \(self.parameterStringRepresentation)|"
    }
    
    public let transformationMatrix: QuAmplitudeMatrix
    public let parameter:Double
    
    public init(parameter:Double) {
        self.parameter = parameter
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: 0.0)
        let exp = pow(M_E, self.parameter.i)
        
        matrix[0, 0] = exp
        matrix[1, 1] = exp
        
        self.transformationMatrix = matrix
    }
}

public struct RotationXGate : UnaryQuBitTransformer, QuBitParameterizedTransformer {
    public var transformerName: String {
        return "|Rx \(self.parameterStringRepresentation)|"
    }
    
    public let transformationMatrix: QuAmplitudeMatrix
    public let parameter:Double
    
    public init(parameter:Double) {
        self.parameter = parameter
        
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: QuAmplitude(0.0, 0.0))
        let radians = self.parameter
        let cosCalc = QuAmplitude(cos(radians/2.0), 0.0)
        let sinCalc = (-sin(radians/2.0)).i
        
        matrix[0, 0] = cosCalc
        matrix[1, 0] = sinCalc
        matrix[0, 1] = sinCalc
        matrix[1, 1] = cosCalc
        
        self.transformationMatrix = matrix
    }
}

public struct RotationYGate : UnaryQuBitTransformer, QuBitParameterizedTransformer {
    public var transformerName: String {
        return "|Ry \(self.parameterStringRepresentation)|"
    }
    
    public let transformationMatrix: QuAmplitudeMatrix
    public let parameter:Double
    
    public init(parameter:Double) {
        self.parameter = parameter
        
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: QuAmplitude(0.0, 0.0))
        let radians = self.parameter
        let cosCalc = QuAmplitude(cos(radians/2.0), 0.0)
        let sinCalc = QuAmplitude(sin(radians/2.0), 0.0)
        
        matrix[0, 0] = cosCalc
        matrix[1, 0] = sinCalc
        matrix[0, 1] = -sinCalc
        matrix[1, 1] = cosCalc
        
        self.transformationMatrix = matrix
    }
}

public struct RotationZGate : UnaryQuBitTransformer, QuBitParameterizedTransformer {
    public var transformerName: String {
        return "|Rz \(self.parameterStringRepresentation)|"
    }
    
    public let transformationMatrix: QuAmplitudeMatrix
    public let parameter:Double
    
    public init(parameter:Double) {
        self.parameter = parameter
        
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: QuAmplitude(0.0, 0.0))
        let radians = self.parameter
        let exp1 = pow(M_E, (-radians/2.0).i)
        let exp2 = pow(M_E, (radians/2.0).i)
        
        matrix[0, 0] = exp1
        matrix[1, 1] = exp2
        
        self.transformationMatrix = matrix
    }
}

public struct SwapGate : BinaryQuBitTransformer {
    public let transformerName: String = "|Swap|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 4, columns: 4, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        
        matrix[0, 0] = one
        matrix[1, 2] = one
        matrix[2, 1] = one
        matrix[3, 3] = one
        
        transformationMatrix = matrix
    }
}

public struct SquareRootOfSwapGate : BinaryQuBitTransformer {
    public let transformerName: String = "|√Swap|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 4, columns: 4, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        let positive = QuAmplitude(0.5, 0.5)
        let negative = QuAmplitude(0.5, -0.5)
        
        matrix[0, 0] = one
        matrix[1, 1] = positive
        matrix[1, 2] = negative
        matrix[2, 1] = negative
        matrix[2, 2] = positive
        matrix[3, 3] = one
        
        transformationMatrix = matrix
    }
}

public struct ControlledNotGate : BinaryQuBitTransformer {
    public let transformerName: String = "|C-NOT|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 4, columns: 4, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        
        matrix[0, 0] = one
        matrix[1, 1] = one
        matrix[2, 3] = one
        matrix[3, 2] = one
        
        transformationMatrix = matrix
    }
}

public struct UniversalControlledGate : BinaryQuBitTransformer {
    public var transformerName: String {
        let trimmedString = gate.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        
        return "|C-\(trimmedString)|"
    }
    
    fileprivate let gate:UnaryQuBitTransformer
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        fatalError("You must use the init(gate:) initializer")
    }
    
    public init(gate:UnaryQuBitTransformer) {
        self.gate = gate
        
        var matrix = QuAmplitudeMatrix(rows: 4, columns: 4, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        
        matrix[0, 0] = one
        matrix[1, 1] = one
        
        let transformationMatrix = gate.transformationMatrix
        matrix[2, 2] = transformationMatrix[0, 0]
        matrix[2, 3] = transformationMatrix[0, 1]
        matrix[3, 2] = transformationMatrix[1, 0]
        matrix[3, 3] = transformationMatrix[1, 1]
        
        self.transformationMatrix = matrix
    }
}

public struct MultiControlMultiTargetControlledGate : MultipleQuBitTransformer {
    public var transformerName: String {
        let trimmedString = targetGate.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        
        var C = ""
        for _ in 0..<numberOfInputs-targetGate.numberOfInputs {
            C += "C-"
        }
        
        return "|\(C)\(trimmedString)|"
    }
    
    public fileprivate(set) var transformationMatrix = QuAmplitudeMatrix(rows:1, columns: 1, repeatedValue: 0.0)
    
    public var numberOfInputs: Int
    public var numberOfOutputs: Int
    
    public fileprivate(set) var targetGate:QuBitTransformer
    
    public init() {
        fatalError("You must use the init(numberOfControlInputs:) initializer")
    }
    
    public init(numberOfControlInputs:Int, targetGate:QuBitTransformer) {
        self.numberOfInputs = numberOfControlInputs+targetGate.numberOfInputs
        self.numberOfOutputs = numberOfInputs
        self.targetGate = targetGate
        
        var matrix = targetGate.transformationMatrix
        for _ in 0..<numberOfControlInputs {
            matrix = self.controlledGate(from: matrix)
        }
        
        self.transformationMatrix = matrix
    }
    
    fileprivate func controlledGate(from refMatrix:QuAmplitudeMatrix) -> QuAmplitudeMatrix {
        let size = refMatrix.rows
        var matrix = QuAmplitudeMatrix.identity(size: size*2)
        for i in 0..<size {
            for j in 0..<size {
                matrix[i + size, j + size] = refMatrix[i, j];
            }
        }
        
        return matrix
    }
}

public struct ToffoliCCNotGate : TernaryQuBitTransformer {
    public let transformerName: String = "|CC-NOT|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 8, columns: 8, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        
        matrix[0, 0] = one
        matrix[1, 1] = one
        matrix[2, 2] = one
        matrix[3, 3] = one
        matrix[4, 4] = one
        matrix[5, 5] = one
        matrix[6, 7] = one
        matrix[7, 6] = one
        
        self.transformationMatrix = matrix
    }
}

public struct UniversalCCGate : TernaryQuBitTransformer {
    public var transformerName: String {
        let trimmedString = gate.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        
        return "|CC-\(trimmedString)|"
    }
    
    fileprivate let gate:UnaryQuBitTransformer
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        fatalError("You must use the init(gate:) initializer")
    }
    
    public init(gate:UnaryQuBitTransformer) {
        self.gate = gate
        
        var matrix = QuAmplitudeMatrix(rows: 8, columns: 8, repeatedValue: QuAmplitude(0.0, 0.0))
        let one = QuAmplitude(1.0, 0.0)
        
        matrix[0, 0] = one
        matrix[1, 1] = one
        matrix[2, 2] = one
        matrix[3, 3] = one
        matrix[4, 4] = one
        matrix[5, 5] = one
        
        let transformationMatrix = gate.transformationMatrix
        
        matrix[6, 6] = transformationMatrix[0, 0]
        matrix[6, 7] = transformationMatrix[0, 1]
        matrix[7, 6] = transformationMatrix[1, 0]
        matrix[7, 7] = transformationMatrix[1, 1]
        
        self.transformationMatrix = matrix
    }
}

public struct FredkinCSwapGate : TernaryQuBitTransformer {
    public let transformerName: String = "|C-SWAP|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 8, columns: 8, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        
        matrix[0, 0] = one
        matrix[1, 1] = one
        matrix[2, 2] = one
        matrix[3, 3] = one
        matrix[4, 4] = one
        matrix[5, 6] = one
        matrix[6, 5] = one
        matrix[7, 7] = one
        
        self.transformationMatrix = matrix
    }
}

public struct CompiledGate : QuBitTransformer {
    public let transformerName: String
    public let transformationMatrix: QuAmplitudeMatrix
    
    public var numberOfInputs: Int {
        return gates.first!.numberOfInputs
    }
    
    public var numberOfOutputs: Int {
        return gates.first!.numberOfOutputs
    }
    
    fileprivate let gates:[QuBitTransformer]
    
    public init() {
        fatalError("You must use the init(name:gates:) initializer")
    }
    
    public init?(name:String, gates:[QuBitTransformer]) {
        let (inputs, outputs) = (gates.first!.numberOfInputs, gates.first!.numberOfOutputs)
        
        for gate in gates {
            if gate.numberOfInputs != inputs || gate.numberOfOutputs != outputs {
                return nil
            }
        }
        
        self.transformerName = "|\(name)|"
        self.gates = [QuBitTransformer](gates)
        
        var matrix = gates.first!.transformationMatrix
        for gate in gates[gates.indices.suffix(from: (gates.startIndex + 1))] {
            matrix = try! matrix*gate.transformationMatrix
        }
        
        self.transformationMatrix = matrix
    }
}

public struct UniversalGate : QuBitTransformer {
    public let transformerName: String
    public let transformationMatrix: QuAmplitudeMatrix
    public let numberOfInputs: Int
    public let numberOfOutputs: Int
    
    public init() {
        fatalError("You must use the init(matrix:name:numberOfInputs:numberOfOutputs) initializer")
    }
    
    public init(matrix:QuAmplitudeMatrix, name:String, numberOfInputs:Int, numberOfOutputs:Int) {
        self.transformerName = name
        self.transformationMatrix = matrix
        self.numberOfInputs = numberOfInputs
        self.numberOfOutputs = numberOfOutputs
    }
}

public struct PoweredGate : QuBitTransformer {
    public let transformerName: String
    public let transformationMatrix: QuAmplitudeMatrix
    public let numberOfInputs: Int
    public let numberOfOutputs: Int
    
    public init() {
        fatalError("You must use the init(gate:exponent:) initializer")
    }
    
    public init(gate:QuBitTransformer, exponent:UInt) {
        let trimmedString = gate.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        let matrix = exponent == 0 ? gate.transformationMatrix : try! pow(gate.transformationMatrix, exponent: exponent)
        
        self.transformerName = "|(\(trimmedString))^\(exponent)|"
        self.transformationMatrix = matrix
        self.numberOfInputs = gate.numberOfInputs
        self.numberOfOutputs = gate.numberOfOutputs
    }
}

public struct QuBitSetter : UnaryQuBitTransformer {
    public let transformerName: String
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        self.init(grounded:true) //can not use a default grounded value, since we need to conform to the protocol
    }
    
    public init(grounded:Bool) {
        var matrix = QuAmplitudeMatrix(rows: 2, columns: 2, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)
        
        let row = grounded ? 0 : 1
        
        matrix[row, 0] = one
        matrix[row, 1] = one
        
        self.transformerName = grounded ? "|0|" : "|1|"
        self.transformationMatrix = matrix
    }
}

public struct QuFTGate : QuBitTransformer {
    public let transformerName: String
    public let transformationMatrix: QuAmplitudeMatrix
    public let numberOfInputs: Int
    public let numberOfOutputs: Int
    public let inverse:Bool
    
    public init() {
        fatalError("You must use the init(gate:exponent:) initializer")
    }
    
    public init(numberOfInputs:Int, inverse:Bool = false) {
        self.transformerName = "|QuFT-\(numberOfInputs)|"
        self.numberOfInputs = numberOfInputs
        self.numberOfOutputs = numberOfInputs
        self.inverse = inverse
        
        let N = pow(2.0, Double(numberOfInputs))
        let intN = Int(N)
        let exp = inverse ? (-2.0*Double.pi.i)/N : (2.0*Double.pi.i)/N
        let w = pow(M_E, exp)
        let mult = 1.0/sqrt(N)
        var matrix = QuAmplitudeMatrix(rows: intN, columns: intN, repeatedValue: QuAmplitude(mult, 0.0))
        
        for i in 1..<intN {
            for j in 1..<intN {
                matrix[i, j] = pow(w, i*j)*mult
            }
        }
        
        self.transformationMatrix = matrix
    }
}

public struct QuMagicBasisGate : BinaryQuBitTransformer {
    public let transformerName: String = "|Magic|"
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init() {
        var matrix = QuAmplitudeMatrix(rows: 4, columns: 4, repeatedValue: 0.0)
        let one = QuAmplitude(1.0, 0.0)/2.0.squareRoot()
        let i = 1.0.i / 2.0.squareRoot()
        
        matrix[0, 0] = one
        matrix[0, 3] = i
        matrix[1, 1] = i
        matrix[1, 2] = one
        matrix[2, 1] = i
        matrix[2, 2] = -one
        matrix[3, 0] = one
        matrix[3, 3] = -i
        
        self.transformationMatrix = matrix
    }
}

public struct QuKrausCiracGate : BinaryQuBitTransformer {
    private var a: Complex
    private var b: Complex
    private var c: Complex
    
    public var transformerName: String {
        return "|N(\(a),\(b),\(c))|"
    }
    public let transformationMatrix: QuAmplitudeMatrix
    
    public init(a: Complex, b: Complex, c: Complex) {
        self.a = a
        self.b = b
        self.c = c
        
        var matrix = QuAmplitudeMatrix(rows: 4, columns: 4, repeatedValue: 0.0)
        let cosAB = cos(a+b)
        let cosA_B = cos(a-b)
        let sinAB = sin(a+b)
        let sinA_B = sin(a-b)
        let Eic = pow(M_E, c*1.0.i)
        let E_ic = pow(M_E, -c*1.0.i)
        
        matrix[0, 0] = Eic*cosA_B
        matrix[0, 3] = 1.0.i*Eic*sinA_B
        matrix[1, 1] = E_ic*cosAB
        matrix[1, 2] = 1.0.i*E_ic*sinAB
        matrix[2, 1] = 1.0.i*E_ic*sinAB
        matrix[2, 2] = E_ic*cosAB
        matrix[3, 0] = 1.0.i*Eic*sinA_B
        matrix[3, 3] = Eic*cosA_B
        
        self.transformationMatrix = matrix
    }
    
    public init() {
        fatalError("You must use the init(a:b:c:) initializer")
    }
}
