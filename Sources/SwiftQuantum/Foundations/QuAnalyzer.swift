//
//  QuAnalyzer.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 31/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

public struct QuAnalyzer {
    public static func truthTable(_ transformer:QuBitTransformer) -> [String:[String:Double]] {
        let numberOfInputs = transformer.numberOfInputs
        let nStates = Int(pow(2.0, Double(numberOfInputs)))
        var result = [String:[String:Double]]()
        var quBits = [QuBit](repeating: .grounded, count: numberOfInputs)
        for k in 0..<nStates {
            let bin = k.binaryRepresentation(numberOfBits: numberOfInputs)
            for (idx, b) in bin.enumerated() {
                if b == "0" {
                    quBits[idx] = .grounded
                }
                else if b == "1" {
                    quBits[idx] = .excited
                }
            }
            
            let matrix = try! transformer.transform(input: QuBit.matrixRepresentation(of: quBits))
            let map = try! QuMeasurer(input: matrix).probabilisticMap()
            result[bin] = map
        }
        
        return result
    }
    
    public static func blochSphereCoordinates(_ quBit:QuBit) -> (x:Double, y:Double, z:Double) {
        let angle1_2 = acos(quBit.groundAmplitude).re
        let angle1 = angle1_2*2.0
        
        let angle2:Double
        if (angle1_2 =~ 0.0) || (quBit.excitedAmplitude =~ 0.0) {
            angle2 = 0.0
        }
        else{
            let oper = quBit.excitedAmplitude/sin(angle1_2)
            let candidate = (log(oper)/1.0.i).re
            
            if candidate.isNaN || candidate.isInfinite {
                angle2 = 0.0
            }
            else {
                angle2 = candidate
            }
        }
        
        let x = sin(angle1)*cos(angle2)
        let y = sin(angle1)*sin(angle2)
        let z = cos(angle1)
        
        return (x, y, z)
    }
}
