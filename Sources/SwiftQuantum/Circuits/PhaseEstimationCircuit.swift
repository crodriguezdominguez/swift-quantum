//
//  PhaseEstimationCircuit.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 18/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

open class PhaseEstimationCircuit : QuCircuit {
    fileprivate let quBitsOfPrecision:Int
    
    public required init(operatorGate:QuBitTransformer, quBitsOfPrecision nPrecision:Int, errorProbability:Double) {
        let mQuBits = operatorGate.numberOfInputs
        let name = operatorGate.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        self.quBitsOfPrecision = nPrecision + Int(ceil(log2(2.0+(1.0/(2.0*errorProbability)))))
        
        super.init(name: "|PhaseEstimation-\(name) \(quBitsOfPrecision)-Precision|", numberOfInputs: mQuBits+quBitsOfPrecision)
        
        let h = HadamardGate()
        let controlledU = MultiControlMultiTargetControlledGate(numberOfControlInputs: 1, targetGate: operatorGate)
        
        var time = 0
        for k in 0..<quBitsOfPrecision {
            try! self.append(transformer: h, atTime: time, forInputAtIndices: [k])
        }
        time += 1
        
        let trimmedString = operatorGate.transformerName.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        let gateName  = "|C-\(trimmedString)|"
        
        let targetQuBits = [Int](quBitsOfPrecision..<quBitsOfPrecision+mQuBits)
        var currentMatrix = controlledU.transformationMatrix
        var lastExp:UInt = 1
        for k in 0..<quBitsOfPrecision {
            let exp = UInt(pow(2.0, Double(k)))
            currentMatrix = try! currentMatrix*pow(controlledU.transformationMatrix, exponent: exp-lastExp)
            let indices = [k]+targetQuBits
            let gate = UniversalGate(matrix: currentMatrix, name: gateName, numberOfInputs: controlledU.numberOfInputs, numberOfOutputs: controlledU.numberOfOutputs)
            try! self.append(transformer: gate, atTime: time, forInputAtIndices: indices)
            
            lastExp = exp
            
            time += 1
        }
        
        try! self.append(transformer: QuFTGate(numberOfInputs: quBitsOfPrecision, inverse: true), atTime: time, forInputAtIndices: [Int](0..<quBitsOfPrecision))
    }
    
    public required init() {
        quBitsOfPrecision = 0
        super.init()
    }
    
    open func estimatePhase(forOperatorInput input:QuRegister) throws -> (phase:Double, probability:Double) {
        let register = QuRegister(numberOfQuBits: quBitsOfPrecision).append(input)
        return try estimatePhase(for: register.matrixRepresentation())
    }
    
    open func estimatePhase(for input:QuAmplitudeMatrix) throws -> (phase:Double, probability:Double) {
        let output = try transform(input: input)
        var (phaseNumerator,prob) = try QuMeasurer(input: output).mostProbableIntegerValue()
        
        //we just take the quBits of precision, not the input for the operator register
        let n:UInt32 = UInt32(self.numberOfInputs-quBitsOfPrecision)
        phaseNumerator = phaseNumerator >> n
        
        return (Double(phaseNumerator) / pow(2.0, Double(quBitsOfPrecision)), prob)
    }
}
