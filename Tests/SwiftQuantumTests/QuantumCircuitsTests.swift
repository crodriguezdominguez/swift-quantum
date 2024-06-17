//
//  QuantumCircuits.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 7/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import XCTest
import SwiftQuantum

class QuantumCircuitsTests : XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSimpleCircuit() {
        let quBit1 = QuBit.grounded
        let quBit2 = QuBit.excited
        
        do {
            let circuit = QuCircuit(name: "Test Circuit", numberOfInputs: 2)
            try circuit.append(transformers: (transformer: PauliYGate(), time: 0, inputIndices:[1]),
                               (transformer: PauliYGate(), time: 0, inputIndices:[0]),
                               (transformer: SwapGate(), time: 1, inputIndices:[0,1]),
                               (transformer: PhaseShiftGate(parameter: .pi / 4.0), time: 2, inputIndices:[0]),
                               (transformer: PhaseShiftGate(parameter: .pi / 4.0), time: 2, inputIndices:[1])
            )
            let result = try circuit.transform(input: QuRegister(quBits: quBit1, quBit2))
            XCTAssertTrue(result.rows == 4 && result.columns == 1)
            XCTAssertTrue(result[0,0] == .zeroAmplitude)
            XCTAssertTrue(result[1,0] == QuAmplitude(cos(.pi/4.0), sin(.pi/4.0)))
            XCTAssertTrue(result[2,0] == .zeroAmplitude)
            XCTAssertTrue(result[3,0] == .zeroAmplitude)
            XCTAssertTrue(circuit.countGates == 5)
        }catch{
            XCTAssert(false)
        }
    }
    
    func testACircuitTransformationIsEqualToTheProductBetweenTheInputAndTheTransformationMatrix() {
        let quBit1 = QuBit.grounded
        let quBit2 = QuBit.excited
        
        do {
            let circuit = QuCircuit(name: "Test Circuit", numberOfInputs: 2)
            try circuit.append(transformers: (transformer: PauliYGate(), time: 0, inputIndices:[1]),
                               (transformer: PauliYGate(), time: 0, inputIndices:[0]),
                               (transformer: SwapGate(), time: 1, inputIndices:[0,1]),
                               (transformer: PhaseShiftGate(parameter: .pi / 4.0), time: 2, inputIndices:[0]),
                               (transformer: PhaseShiftGate(parameter: .pi / 4.0), time: 2, inputIndices:[1])
            )
            let result1 = try circuit.transform(input: QuRegister(quBits: quBit1, quBit2))
            let result2 = try circuit.transformationMatrix*QuBit.matrixRepresentation(of: quBit1, quBit2)
            
            XCTAssertTrue(result1 == result2)
            
            let quft = QuFTGate(numberOfInputs: 5).circuitImplementation
            let result3 = try quft.transform(input: QuRegister(quBits: quBit1, quBit2, quBit1, quBit2, quBit1))
            let result4 = try quft.transformationMatrix*QuBit.matrixRepresentation(of: quBit1, quBit2, quBit1, quBit2, quBit1)
            
            XCTAssertTrue(result3 == result4)
        }
        catch{
            XCTAssert(false)
        }
    }
    
    func testInvertedControlledNotIsEqualToHadamardControlledNotAndHadamardCircuit() {
        let quBit1 = QuBit(groundAmplitude: 1.0.i, excitedAmplitude: .zeroAmplitude)
        let quBit2 = QuBit(groundAmplitude: .zeroAmplitude, excitedAmplitude: .oneAmplitude)
        
        do {
            let invControlledResult = ControlledNotGate().transform(input: (quBit2, quBit1))
            
            let circuit = QuCircuit(name: "InvCNOT Circuit", numberOfInputs: 2)
            try circuit.append(transformers: (transformer: HadamardGate(), time: 0, inputIndices:[0]),
                               (transformer: HadamardGate(), time: 0, inputIndices:[1]),
                               (transformer: ControlledNotGate(), time: 1, inputIndices:[0, 1]),
                               (transformer: HadamardGate(), time: 2, inputIndices:[0]),
                               (transformer: HadamardGate(), time: 2, inputIndices:[1])
            )
            
            let circuitResult = try circuit.transform(input: QuRegister(quBits: quBit1, quBit2))
            
            let result1 = try QuMeasurer(input: invControlledResult).probabilisticMap()
            let result2 = try QuMeasurer(input: circuitResult).probabilisticMap()
            
            XCTAssertTrue(result1 == result2)
        } catch{
            XCTAssert(false)
        }
    }
    
    func testSwapTransformationMatrixEqualsItsCircuitImplementation() {
        let quBit1 = QuBit(groundAmplitude: 1.0.i, excitedAmplitude: .zeroAmplitude)
        let quBit2 = QuBit(groundAmplitude: .zeroAmplitude, excitedAmplitude: .oneAmplitude)
        
        do {
            let swappedQuBits = SwapGate().transform(input: (quBit1, quBit2))
            let swappedQuBits2 = SwapGate().transform(input: (quBit2, quBit1))
            
            let circuit = SwapGate().circuitImplementation
            let result1 = try circuit.transform(input: QuRegister(quBits: quBit1, quBit2))
            let result2 = try circuit.transform(input: QuRegister(quBits: quBit2, quBit1))
            
            XCTAssertTrue(swappedQuBits == result1)
            XCTAssertTrue(swappedQuBits2 == result2)
        } catch{
            XCTAssert(false)
        }
    }
    
    func testQFT2() {
        let circuit = QuFTGate(numberOfInputs:2).circuitImplementation
        
        //00
        let register1 = QuRegister(quBits: QuBit.grounded, QuBit.grounded)
        let output1 = try! circuit.transform(input: register1)
        let map1 = try! QuMeasurer(input: output1).probabilisticMap()
        XCTAssertTrue(map1.count == 4)
        let probability1 = map1.values.first!
        for p in map1.values {
            XCTAssertTrue(probability1 =~ p)
        }
        
        //01
        let register2 = QuRegister(quBits: QuBit.grounded, QuBit.excited)
        let output2 = try! circuit.transform(input: register2)
        let map2 = try! QuMeasurer(input: output2).probabilisticMap()
        XCTAssertTrue(map2.count == 4)
        let probability2 = map2.values.first!
        for p in map2.values {
            XCTAssertTrue(probability2 =~ p)
        }
        
        //10
        let register3 = QuRegister(quBits: QuBit.excited, QuBit.grounded)
        let output3 = try! circuit.transform(input: register3)
        let map3 = try! QuMeasurer(input: output3).probabilisticMap()
        XCTAssertTrue(map3.count == 4)
        let probability3 = map3.values.first!
        for p in map3.values {
            XCTAssertTrue(probability3 =~ p)
        }
        
        //11
        let register4 = QuRegister(quBits: QuBit.excited, QuBit.excited)
        let output4 = try! circuit.transform(input: register4)
        let map4 = try! QuMeasurer(input: output4).probabilisticMap()
        XCTAssertTrue(map4.count == 4)
        let probability4 = map4.values.first!
        for p in map4.values {
            XCTAssertTrue(probability4 =~ p)
        }
    }
    
    func testQFT3() {
        let circuit = QuFTGate(numberOfInputs:3).circuitImplementation
        
        //000
        let register1 = QuRegister(quBits: QuBit.grounded, QuBit.grounded, QuBit.grounded)
        let output1 = try! circuit.transform(input: register1)
        let map1 = try! QuMeasurer(input: output1).probabilisticMap()
        XCTAssertTrue(map1.count == 8)
        let probability1 = map1.values.first!
        for p in map1.values {
            XCTAssertTrue(probability1 =~ p)
        }
        
        //010
        let register2 = QuRegister(quBits: QuBit.grounded, QuBit.excited, QuBit.grounded)
        let output2 = try! circuit.transform(input: register2)
        let map2 = try! QuMeasurer(input: output2).probabilisticMap()
        XCTAssertTrue(map2.count == 8)
        let probability2 = map2.values.first!
        for p in map2.values {
            XCTAssertTrue(probability2 =~ p)
        }
        
        //101
        let register3 = QuRegister(quBits: QuBit.excited, QuBit.grounded, QuBit.excited)
        let output3 = try! circuit.transform(input: register3)
        let map3 = try! QuMeasurer(input: output3).probabilisticMap()
        XCTAssertTrue(map3.count == 8)
        let probability3 = map3.values.first!
        for p in map3.values {
            XCTAssertTrue(probability3 =~ p)
        }
        
        //111
        let register4 = QuRegister(quBits: QuBit.excited, QuBit.excited, QuBit.excited)
        let output4 = try! circuit.transform(input: register4)
        let map4 = try! QuMeasurer(input: output4).probabilisticMap()
        XCTAssertTrue(map4.count == 8)
        let probability4 = map4.values.first!
        for p in map4.values {
            XCTAssertTrue(probability4 =~ p)
        }
    }
    
    func testQFT4() {
        let circuit = QuFTGate(numberOfInputs:4).circuitImplementation
        
        //0000
        let register1 = QuRegister(quBits: .grounded, .grounded, .grounded, .grounded)
        let output1 = try! circuit.transform(input: register1)
        let map1 = try! QuMeasurer(input: output1).probabilisticMap()
        XCTAssertTrue(map1.count == 16)
        let probability1 = map1.values.first!
        for p in map1.values {
            XCTAssertTrue(probability1 =~ p)
        }
        
        //1111
        let register2 = QuRegister(quBits: .excited, .excited, .excited, .excited)
        let output2 = try! circuit.transform(input: register2)
        let map2 = try! QuMeasurer(input: output2).probabilisticMap()
        XCTAssertTrue(map2.count == 16)
        let probability2 = map2.values.first!
        for p in map2.values {
            XCTAssertTrue(probability2 =~ p)
        }
        
        //0110
        let register3 = QuRegister(quBits: .grounded, .excited, .excited, .grounded)
        let output3 = try! circuit.transform(input: register3)
        let map3 = try! QuMeasurer(input: output3).probabilisticMap()
        XCTAssertTrue(map3.count == 16)
        let probability3 = map3.values.first!
        for p in map3.values {
            XCTAssertTrue(probability3 =~ p)
        }
        
        //1001
        let register4 = QuRegister(quBits: .excited, .grounded, .grounded, .excited)
        let output4 = try! circuit.transform(input: register4)
        let map4 = try! QuMeasurer(input: output4).probabilisticMap()
        XCTAssertTrue(map4.count == 16)
        let probability4 = map4.values.first!
        for p in map4.values {
            XCTAssertTrue(probability4 =~ p)
        }
    }
    
    func testInverseQFTCircuitOfQFTCircuitIsEqualToInitialInput() {
        let circuit = QuFTGate(numberOfInputs: 4).circuitImplementation
        let invCircuit = QuFTGate(numberOfInputs: 4, inverse: true).circuitImplementation
        
        do {
            let input = QuRegister(quBits: .grounded, .excited, .grounded, .excited)
            let output = try circuit.transform(input: input)
            let invOutput = try invCircuit.transform(input: output)
            let measurer = try QuMeasurer(input: invOutput)
            let map = measurer.probabilisticMap()
            let (quBits, _) = measurer.mostProbableQuBits()
            
            XCTAssertTrue(map["0101"] == 1.0)
            XCTAssertTrue(quBits == Array(input))
        }catch{
            XCTAssert(false)
        }
    }
    
    func testQFTTransformationMatrixEqualsItsCircuitImplementation() {
        let maxAllowedError = 0.000000000001 //we are flexible, since there can be a lot of precision errors
        
        let qft1 = QuFTGate(numberOfInputs: 3).circuitImplementation
        let matrix1 = QuFTGate(numberOfInputs: 3).transformationMatrix
        
        for i in 0..<matrix1.rows {
            for j in 0..<matrix1.columns {
                XCTAssertTrue(abs(qft1.transformationMatrix[i, j] - matrix1[i, j]) <= maxAllowedError)
            }
        }
        
        let qft2 = QuFTGate(numberOfInputs: 4).circuitImplementation
        let matrix2 = QuFTGate(numberOfInputs: 4).transformationMatrix
        
        for i in 0..<matrix2.rows {
            for j in 0..<matrix2.columns {
                XCTAssertTrue(abs(qft2.transformationMatrix[i, j] - matrix2[i, j]) <= maxAllowedError)
            }
        }
    }
    
    func testInvQFTTransformationMatrixEqualsItsCircuitImplementation() {
        let maxAllowedError = 0.000000000001 //we are flexible, since there can be a lot of precision errors
        
        let qft1 = QuFTGate(numberOfInputs: 3, inverse: true).circuitImplementation
        let matrix1 = QuFTGate(numberOfInputs: 3, inverse: true).transformationMatrix
        
        for i in 0..<matrix1.rows {
            for j in 0..<matrix1.columns {
                XCTAssertTrue(abs(qft1.transformationMatrix[i, j] - matrix1[i, j]) <= maxAllowedError)
            }
        }
        
        let qft2 = QuFTGate(numberOfInputs: 4, inverse: true).circuitImplementation
        let matrix2 = QuFTGate(numberOfInputs: 4, inverse: true).transformationMatrix
        
        for i in 0..<matrix2.rows {
            for j in 0..<matrix2.columns {
                XCTAssertTrue(abs(qft2.transformationMatrix[i, j] - matrix2[i, j]) <= maxAllowedError)
            }
        }
    }
    
    func testGenericQFTCircuitIsEqualToManuallyMadeOnes() {
        let h = HadamardGate()
        let pi2 = UniversalControlledGate(gate: PhaseGate(parameter: .pi / 2.0))
        let pi4 = UniversalControlledGate(gate: PhaseGate(parameter: .pi / 4.0))
        let pi8 = UniversalControlledGate(gate: PhaseGate(parameter: .pi / 8.0))
        let swap = SwapGate()
        
        let quft1 = QuCircuit(name: "|QuFT-1|", numberOfInputs: 1)
        try! quft1.append(transformer: h, atTime: 0, forInputAtIndices: [0])
        
        XCTAssertTrue(quft1 == QuFTGate(numberOfInputs:1).circuitImplementation)
        
        let quft2 = QuCircuit(name: "|QuFT-2|", numberOfInputs: 2)
        try! quft2.append(transformer: h, atTime: 0, forInputAtIndices: [0])
        try! quft2.append(transformer: pi2, atTime: 1, forInputAtIndices: [1, 0])
        try! quft2.append(transformer: h, atTime: 2, forInputAtIndices: [1])
        try! quft2.append(transformer: swap, atTime: 3, forInputAtIndices: [0, 1])
        
        XCTAssertTrue(quft2 == QuFTGate(numberOfInputs:2).circuitImplementation)
        
        let quft3 = QuCircuit(name: "|QuFT-3|", numberOfInputs: 3)
        try! quft3.append(transformer: h, atTime: 0, forInputAtIndices: [0])
        try! quft3.append(transformer: pi2, atTime: 1, forInputAtIndices: [1, 0])
        try! quft3.append(transformer: pi4, atTime: 2, forInputAtIndices: [2, 0])
        
        try! quft3.append(transformer: h, atTime: 3, forInputAtIndices: [1])
        try! quft3.append(transformer: pi2, atTime: 4, forInputAtIndices: [2, 1])
        
        try! quft3.append(transformer: h, atTime: 5, forInputAtIndices: [2])
        
        try! quft3.append(transformer: swap, atTime: 6, forInputAtIndices: [0, 2])
        
        XCTAssertTrue(quft3 == QuFTGate(numberOfInputs:3).circuitImplementation)
        
        let quft4 = QuCircuit(name: "|QuFT-4|", numberOfInputs: 4)
        try! quft4.append(transformer: h, atTime: 0, forInputAtIndices: [0])
        try! quft4.append(transformer: pi2, atTime: 1, forInputAtIndices: [1, 0])
        try! quft4.append(transformer: pi4, atTime: 2, forInputAtIndices: [2, 0])
        try! quft4.append(transformer: pi8, atTime: 3, forInputAtIndices: [3, 0])
        
        try! quft4.append(transformer: h, atTime: 4, forInputAtIndices: [1])
        try! quft4.append(transformer: pi2, atTime: 5, forInputAtIndices: [2, 1])
        try! quft4.append(transformer: pi4, atTime: 6, forInputAtIndices: [3, 1])
        
        try! quft4.append(transformer: h, atTime: 7, forInputAtIndices: [2])
        try! quft4.append(transformer: pi2, atTime: 8, forInputAtIndices: [3, 2])
        
        try! quft4.append(transformer: h, atTime: 9, forInputAtIndices: [3])
        
        try! quft4.append(transformer: swap, atTime: 10, forInputAtIndices: [0, 3])
        try! quft4.append(transformer: swap, atTime: 11, forInputAtIndices: [1, 2])
        
        XCTAssertTrue(quft4 == QuFTGate(numberOfInputs:4).circuitImplementation)
    }
    
    func testSimpleOracleCircuitsForGroverAlgorithm() {
        let x = PauliXGate()
        let cNot = MultiControlMultiTargetControlledGate(numberOfControlInputs: 3, targetGate: ControlledNotGate())
        
        do{
            //find a 7
            let oracleCircuit = QuCircuit(name: "Oracle-7", numberOfInputs: 5)
            try oracleCircuit.append(transformer: x, atTime: 0, forInputAtIndices: [0])
            try oracleCircuit.append(transformer: cNot, atTime: 1, forInputAtIndices: [0,1,2,3,4])
            try oracleCircuit.append(transformer: x, atTime: 2, forInputAtIndices: [0])
            
            let result1 = try oracleCircuit.transform(input: QuRegister(quBits: .grounded, .grounded, .grounded, .grounded, .excited))
            let prob1 = try QuMeasurer(input: result1).probabilisticMap()
            XCTAssertTrue(prob1["00001"] == 1.0) //the bits are kepts
            
            let result2 = try oracleCircuit.transform(input: QuRegister(quBits: .grounded, .excited, .excited, .excited, .excited))
            let prob2 = try QuMeasurer(input: result2).probabilisticMap()
            XCTAssertTrue(prob2["01110"] == 1.0) //a not is applied to the last bit
            
            //find a 5
            let oracleCircuit2 = QuCircuit(name: "Oracle-5", numberOfInputs: 5)
            try oracleCircuit2.append(transformer: x, atTime: 0, forInputAtIndices: [0])
            try oracleCircuit2.append(transformer: x, atTime: 0, forInputAtIndices: [2])
            try oracleCircuit2.append(transformer: cNot, atTime: 1, forInputAtIndices: [0,1,2,3,4])
            try oracleCircuit2.append(transformer: x, atTime: 2, forInputAtIndices: [0])
            try oracleCircuit2.append(transformer: x, atTime: 2, forInputAtIndices: [2])
            
            let result3 = try oracleCircuit2.transform(input: QuRegister(quBits: .grounded, .excited, .grounded, .excited, .excited))
            let prob3 = try QuMeasurer(input: result3).probabilisticMap()
            XCTAssertTrue(prob3["01010"] == 1.0) //a not is applied to the last bit
            
            let result4 = try oracleCircuit2.transform(input: QuRegister(quBits: .grounded, .excited, .excited, .excited, .excited))
            let prob4 = try QuMeasurer(input: result4).probabilisticMap()
            XCTAssertTrue(prob4["01111"] == 1.0) //a not is applied to the last bit
        }catch {
            XCTAssert(false)
        }
    }
    
    func testGrooverCircuitCanFindANumberUsingAnOracleWithAHighProbability() {
        let x = PauliXGate()
        let cNot = MultiControlMultiTargetControlledGate(numberOfControlInputs: 3, targetGate: ControlledNotGate())
        
        do{
            //find a 7
            let oracleCircuit = QuCircuit(name: "Oracle-7", numberOfInputs: 5)
            try oracleCircuit.append(transformer: x, atTime: 0, forInputAtIndices: [0])
            try oracleCircuit.append(transformer: cNot, atTime: 1, forInputAtIndices: [0,1,2,3,4])
            try oracleCircuit.append(transformer: x, atTime: 2, forInputAtIndices: [0])
            
            let groverCircuit = GroverCircuit(oracle: oracleCircuit)
            let matrix = groverCircuit.evaluate()
            let measurer = try QuMeasurer(input: matrix)
            let map = measurer.probabilisticMap()
            let (maxKey, maxProb) = map.max{$0.1 < $1.1 }!
            
            XCTAssertTrue(maxKey[maxKey.startIndex..<maxKey.index(before: maxKey.endIndex)] == "0111") // a 7
            XCTAssertTrue(maxProb > 0.95)
            
            //find a 5
            let oracleCircuit2 = QuCircuit(name: "Oracle-5", numberOfInputs: 5)
            try oracleCircuit2.append(transformer: x, atTime: 0, forInputAtIndices: [0])
            try oracleCircuit2.append(transformer: x, atTime: 0, forInputAtIndices: [2])
            try oracleCircuit2.append(transformer: cNot, atTime: 1, forInputAtIndices: [0,1,2,3,4])
            try oracleCircuit2.append(transformer: x, atTime: 2, forInputAtIndices: [0])
            try oracleCircuit2.append(transformer: x, atTime: 2, forInputAtIndices: [2])
            
            let groverCircuit2 = GroverCircuit(oracle: oracleCircuit2)
            let matrix2 = groverCircuit2.evaluate()
            let measurer2 = try QuMeasurer(input: matrix2)
            let map2 = measurer2.probabilisticMap()
            let (maxKey2, maxProb2) = map2.max{ $0.1 < $1.1 }!
            
            XCTAssertTrue(maxKey2[maxKey.startIndex..<maxKey.index(before: maxKey.endIndex)] == "0101") // a 5
            XCTAssertTrue(maxProb2 > 0.95)
        }catch {
            XCTAssert(false)
        }
    }
    
    func testMultiControlMultiTargetControlledGateIsEqualToSeveralControlledGates() {
        do {
            let gate = HadamardGate()
            
            let controlledX = UniversalControlledGate(gate: gate)
            let refCircuit = QuCircuit(name: "Ref", numberOfInputs: 4, numberOfOutputs: 4)
            try refCircuit.append(transformers:
                                (transformer: controlledX, time: 0, inputIndices: [0, 1]),
                                (transformer: controlledX, time: 1, inputIndices: [0, 2]),
                                (transformer: controlledX, time: 2, inputIndices: [0, 3]))
            let refResult = try refCircuit.transform(input: QuRegister(quBits: .excited, .grounded, .grounded, .grounded))
            
            let multiXCircuit = QuCircuit(name: "Test", numberOfInputs: 3, numberOfOutputs: 3)
            try multiXCircuit.append(transformers:
                                        (transformer: gate, time: 0, inputIndices: [0]),
                                        (transformer: gate, time: 0, inputIndices: [1]),
                                        (transformer: gate, time: 0, inputIndices: [2]))
            
            let multiX = MultiControlMultiTargetControlledGate(numberOfControlInputs: 1, targetGate: multiXCircuit)
            let testResult = try multiX.transform(input: QuRegister(quBits: .excited, .grounded, .grounded, .grounded))
            
            XCTAssertTrue(refResult == testResult)
        }catch{
            XCTAssert(false)
        }

    }
    
    func testPhaseEstimationCircuitCanFindThePhaseOfAFunctionWithAManagedError() {
        do {
            let precision = 4
            let errorProbability = 0.1
            let maxAllowedError = 1.0/pow(2.0, Double(precision-1))
            
            let phase1 = 2.0/3.0
            let circuit1 = self.phaseEstimationCircuit(forRealPhase: phase1, precision: precision, errorProbability: errorProbability)
            let (estPhase1, _) = try circuit1.estimatePhase(forOperatorInput: QuRegister(quBits: .excited))
            
            XCTAssertTrue(abs(estPhase1-phase1) <= maxAllowedError)
            
            let phase2 = 1.0/3.0
            let circuit2 = self.phaseEstimationCircuit(forRealPhase: phase2, precision: precision, errorProbability: errorProbability)
            let (estPhase2, _) = try circuit2.estimatePhase(forOperatorInput: QuRegister(quBits: .excited))
            XCTAssertTrue(abs(estPhase2-phase2) <= maxAllowedError)
            
            let phase3 = 0.95 //the phase estimator can estimate from in the interval [0,1)
            let circuit3 = self.phaseEstimationCircuit(forRealPhase: phase3, precision: precision, errorProbability: errorProbability)
            let (estPhase3, _) = try circuit3.estimatePhase(forOperatorInput: QuRegister(quBits: .excited))
            XCTAssertTrue(abs(estPhase3-phase3) <= maxAllowedError)
            
            let phase4 = 0.0
            let circuit4 = self.phaseEstimationCircuit(forRealPhase: phase4, precision: precision, errorProbability: errorProbability)
            let (estPhase4, _) = try circuit4.estimatePhase(forOperatorInput: QuRegister(quBits: .excited))
            XCTAssertTrue(abs(estPhase4-phase4) <= maxAllowedError)
        }catch{
            XCTAssert(false)
        }
    }
    
    fileprivate func phaseEstimationCircuit(forRealPhase phase:Double, precision:Int, errorProbability:Double) -> PhaseEstimationCircuit {
        let transformer = PhaseGate(parameter: phase)
        return PhaseEstimationCircuit(operatorGate: transformer, quBitsOfPrecision: precision, errorProbability: errorProbability)
    }
    
    func testCircuitIO() {
        let x = PauliXGate()
        let cNot = MultiControlMultiTargetControlledGate(numberOfControlInputs: 3, targetGate: ControlledNotGate())
        
        do {
            let oracleCircuit = QuCircuit(name: "Oracle-7", numberOfInputs: 5)
            try oracleCircuit.append(transformer: x, atTime: 0, forInputAtIndices: [0])
            try oracleCircuit.append(transformer: cNot, atTime: 1, forInputAtIndices: [0,1,2,3,4])
            try oracleCircuit.append(transformer: x, atTime: 2, forInputAtIndices: [0])
            
            let testCircuit1 = QuFTGate(numberOfInputs: 5).circuitImplementation
            let testCircuit2 = GroverCircuit(oracle: oracleCircuit)
            
            let deserializedCircuit1 = try QuCircuitSerializer.deserialize(QuCircuitSerializer.serialize(testCircuit1))
            let deserializedCircuit2 = try QuCircuitSerializer.deserialize(QuCircuitSerializer.serialize(testCircuit2))
            
            XCTAssertTrue(testCircuit1 == deserializedCircuit1)
            XCTAssertTrue(testCircuit2 == deserializedCircuit2)
            
            let matrixQft1 = try testCircuit1.transform(input: QuRegister(quBits: .excited, .grounded, .excited, .grounded, .grounded))
            let matrixQft2 = try deserializedCircuit1.transform(input: QuRegister(quBits: .excited, .grounded, .excited, .grounded, .grounded))
            
            for i in 0..<matrixQft1.rows {
                for j in 0..<matrixQft1.columns {
                    XCTAssertTrue(matrixQft1[i,j] =~ matrixQft2[i,j])
                }
            }
        }catch{
            XCTAssert(false)
        }
    }
    
    func testIncrementerWorksAsExpected() {
        let N = 5
        let maxN = Int(pow(2.0, Double(N)))
        let incrementer = IncrementerCircuit(modulus: maxN)
        var register = QuRegister(numberOfQuBits: N)
        
        do {
            for k in 0..<maxN {
                XCTAssertTrue(register.mostProbableIntegerValue() == UInt32(k))
                register = try incrementer.increment(register)
            }
            
            //since it is increment mod N, then it should start again
            for k in 0..<maxN {
                XCTAssertTrue(register.mostProbableIntegerValue() == UInt32(k))
                register = try incrementer.increment(register)
            }
        }catch {
            XCTAssert(false)
        }
    }
    
    func testDecrementerWorksAsExpected() {
        let N = 5
        let maxN = Int(pow(2.0, Double(N)))
        let decrementer = DecrementerCircuit(modulus: maxN)
        var register = QuRegister(fromNumber: 31)
        
        do {
            for k in (0..<maxN).reversed() {
                XCTAssertTrue(register.mostProbableIntegerValue() == UInt32(k))
                register = try decrementer.decrement(register)
            }
            
            //since it is decrement mod N, then it should start again
            for k in (0..<maxN).reversed() {
                XCTAssertTrue(register.mostProbableIntegerValue() == UInt32(k))
                register = try decrementer.decrement(register)
            }
        }catch {
            XCTAssert(false)
        }
    }
    
    func testHalfAdderWorksAsExpected() {
        let hadder = HalfTwoQuBitsAdderCircuit()
        XCTAssertTrue(hadder.add(first: .grounded, second: .grounded) == (result:QuBit.grounded, carry: QuBit.grounded))
        XCTAssertTrue(hadder.add(first: .grounded, second: .excited) == (result:QuBit.excited, carry: QuBit.grounded))
        XCTAssertTrue(hadder.add(first: .excited, second: .grounded) == (result:QuBit.excited, carry: QuBit.grounded))
        XCTAssertTrue(hadder.add(first: .excited, second: .excited) == (result:QuBit.grounded, carry: QuBit.excited))
    }
    
    func testHalfSubtractorWorksAsExpected() {
        let hsubs = HalfTwoQuBitsSubtractorCircuit()
        XCTAssertTrue(hsubs.subtract(first: .grounded, second: .grounded) == (result:QuBit.grounded, borrow: QuBit.grounded))
        XCTAssertTrue(hsubs.subtract(first: .grounded, second: .excited) == (result:QuBit.excited, borrow: QuBit.excited))
        XCTAssertTrue(hsubs.subtract(first: .excited, second: .grounded) == (result:QuBit.excited, borrow: QuBit.grounded))
        XCTAssertTrue(hsubs.subtract(first: .excited, second: .excited) == (result:QuBit.grounded, borrow: QuBit.grounded))
    }
    
    func testFullAdderWorksAsExpected() {
        let adder = FullTwoQuBitsAdderCircuit()
        XCTAssertTrue(adder.add(first: .grounded, second: .grounded, carry: .grounded) == (result:QuBit.grounded, carry: QuBit.grounded))
        XCTAssertTrue(adder.add(first: .grounded, second: .excited, carry: .grounded) == (result:QuBit.excited, carry: QuBit.grounded))
        XCTAssertTrue(adder.add(first: .excited, second: .grounded, carry: .grounded) == (result:QuBit.excited, carry: QuBit.grounded))
        XCTAssertTrue(adder.add(first: .excited, second: .excited, carry: .grounded) == (result:QuBit.grounded, carry: QuBit.excited))
        
        XCTAssertTrue(adder.add(first: .grounded, second: .grounded, carry: .excited) == (result:QuBit.excited, carry: QuBit.grounded))
        XCTAssertTrue(adder.add(first: .grounded, second: .excited, carry: .excited) == (result:QuBit.grounded, carry: QuBit.excited))
        XCTAssertTrue(adder.add(first: .excited, second: .grounded, carry: .excited) == (result:QuBit.grounded, carry: QuBit.excited))
        XCTAssertTrue(adder.add(first: .excited, second: .excited, carry: .excited) == (result:QuBit.excited, carry: QuBit.excited))
    }
    
    func testFullSubtractorWorksAsExpected() {
        let subs = FullTwoQuBitsSubtractorCircuit()
        XCTAssertTrue(subs.subtract(first: .grounded, second: .grounded, borrow: .grounded) == (result:QuBit.grounded, borrow: QuBit.grounded))
        XCTAssertTrue(subs.subtract(first: .grounded, second: .excited, borrow: .grounded) == (result:QuBit.excited, borrow: QuBit.excited))
        XCTAssertTrue(subs.subtract(first: .excited, second: .grounded, borrow: .grounded) == (result:QuBit.excited, borrow: QuBit.grounded))
        XCTAssertTrue(subs.subtract(first: .excited, second: .excited, borrow: .grounded) == (result:QuBit.grounded, borrow: QuBit.grounded))
        
        XCTAssertTrue(subs.subtract(first: .grounded, second: .grounded, borrow: .excited) == (result:QuBit.excited, borrow: QuBit.excited))
        XCTAssertTrue(subs.subtract(first: .grounded, second: .excited, borrow: .excited) == (result:QuBit.grounded, borrow: QuBit.excited))
        XCTAssertTrue(subs.subtract(first: .excited, second: .grounded, borrow: .excited) == (result:QuBit.grounded, borrow: QuBit.grounded))
        XCTAssertTrue(subs.subtract(first: .excited, second: .excited, borrow: .excited) == (result:QuBit.excited, borrow: QuBit.excited))
    }
    
    func testAdderWorksAsExpected() {
        let N = 2
        let maxN = Int(pow(2.0, Double(N)))
        let adder = AdderCircuit(modulus: maxN)
        let register1 = QuRegister(fromNumber: 1, minNumberOfQuBits: N)
        let register2 = QuRegister(fromNumber: 2, minNumberOfQuBits: N)
        
        let register3 = QuRegister(fromNumber: 2, minNumberOfQuBits: N)
        let register4 = QuRegister(fromNumber: 2, minNumberOfQuBits: N)
        
        let register5 = QuRegister(fromNumber: 2, minNumberOfQuBits: N)
        let register6 = QuRegister(fromNumber: 3, minNumberOfQuBits: N)
        
        do {
            let result1 = try adder.add(first: register1, second: register2, carry: .grounded)
            XCTAssertTrue(result1.result.mostProbableIntegerValue() == 3)
            XCTAssertTrue(result1.carry == .grounded)
            
            let result2 = try adder.add(first: register3, second: register4, carry: .grounded)
            XCTAssertTrue(result2.result.mostProbableIntegerValue() == 0)
            XCTAssertTrue(result2.carry == .excited)
            
            let result3 = try adder.add(first: register5, second: register6, carry: .grounded)
            XCTAssertTrue(result3.result.mostProbableIntegerValue() == 1)
            XCTAssertTrue(result3.carry == .excited)
        }catch {
            XCTAssert(false)
        }
    }
    
    func testSubtractorWorksAsExpected() {
        let N = 2
        let maxN = Int(pow(2.0, Double(N)))
        let subs = SubtractorCircuit(modulus: maxN)
        let register1 = QuRegister(fromNumber: 1, minNumberOfQuBits: N)
        let register2 = QuRegister(fromNumber: 2, minNumberOfQuBits: N)
        
        let register3 = QuRegister(fromNumber: 2, minNumberOfQuBits: N)
        let register4 = QuRegister(fromNumber: 2, minNumberOfQuBits: N)
        
        let register5 = QuRegister(fromNumber: 3, minNumberOfQuBits: N)
        let register6 = QuRegister(fromNumber: 1, minNumberOfQuBits: N)
        
        do {
            let result1 = try subs.subtract(first: register1, second: register2, borrow: .grounded)
            XCTAssertTrue(result1.result.mostProbableIntegerValue() == 3)
            XCTAssertTrue(result1.borrow == .excited)
            
            let result2 = try subs.subtract(first: register3, second: register4, borrow: .grounded)
            XCTAssertTrue(result2.result.mostProbableIntegerValue() == 0)
            XCTAssertTrue(result2.borrow == .grounded)
            
            let result3 = try subs.subtract(first: register5, second: register6, borrow: .grounded)
            XCTAssertTrue(result3.result.mostProbableIntegerValue() == 2)
            XCTAssertTrue(result3.borrow == .grounded)
        }catch {
            XCTAssert(false)
        }
    }
    
    func testAdderIsReversible() {
        let N = 2
        let maxN = Int(pow(2.0, Double(N)))
        let adder = AdderCircuit(modulus: maxN)
        let register1 = QuRegister(fromNumber: 3, minNumberOfQuBits: N)
        let register2 = QuRegister(fromNumber: 1, minNumberOfQuBits: N)
        
        let quBits = register1.quBits+register2.quBits+([QuBit](repeating: .grounded, count: N))+[.grounded]
        
        do {
            let matrix = try adder.transform(input: QuRegister(quBits: quBits))
            let matrix2 = try adder.transform(input: matrix)
            let quBitsTest = try QuMeasurer(input: matrix2).mostProbableQuBits().quBits
            
            XCTAssertTrue(quBitsTest[0..<(2*N)] == quBits[0..<(2*N)])
        }catch {
            XCTAssert(false)
        }
    }
    
    func testSubtractorIsReversible() {
        let N = 2
        let maxN = Int(pow(2.0, Double(N)))
        let subs = SubtractorCircuit(modulus: maxN)
        let register1 = QuRegister(fromNumber: 3, minNumberOfQuBits: N)
        let register2 = QuRegister(fromNumber: 1, minNumberOfQuBits: N)
        
        let quBits = register1.quBits+register2.quBits+([QuBit](repeating: .grounded, count: N))+[.grounded]
        
        do {
            let matrix = try subs.transform(input: QuRegister(quBits: quBits))
            let matrix2 = try subs.transform(input: matrix)
            let quBitsTest = try QuMeasurer(input: matrix2).mostProbableQuBits().quBits
            
            XCTAssertTrue(quBitsTest[0..<(2*N)] == quBits[0..<(2*N)])
        }catch {
            XCTAssert(false)
        }
    }
    
    //NOTE: The adder/substractor circuits are very slow, since they require 3*N+1 gates to operate. The +/- operators are optimized.
    
    func testOptimizedAdderWorksAsExpected() {
        let register1 = QuRegister(fromNumber: 12)
        let register2 = QuRegister(fromNumber: 5)
        
        let register3 = QuRegister(fromNumber: 2)
        let register4 = QuRegister(fromNumber: 21)
        
        let register5 = QuRegister(fromNumber: 625)
        let register6 = QuRegister(fromNumber: 90)
        
        let register7 = QuRegister(fromNumber: 1, minNumberOfQuBits: 5)
        let register8 = QuRegister(fromNumber: 1, minNumberOfQuBits: 4)
        
        XCTAssertTrue((register1+register2).mostProbableIntegerValue() == 17)
        XCTAssertTrue((register3+register4).mostProbableIntegerValue() == 23)
        XCTAssertTrue((register5+register6).mostProbableIntegerValue() == 715)
        XCTAssertTrue((register7+register8).mostProbableIntegerValue() == 2)
    }
    
    func testOptimizedSubtractorWorksAsExpected() {
        let register1 = QuRegister(fromNumber: 12)
        let register2 = QuRegister(fromNumber: 5)
        
        let register3 = QuRegister(fromNumber: 2)
        let register4 = QuRegister(fromNumber: 21)
        
        let register5 = QuRegister(fromNumber: 625)
        let register6 = QuRegister(fromNumber: 90)
        
        let register7 = QuRegister(fromNumber: 1, minNumberOfQuBits: 5)
        let register8 = QuRegister(fromNumber: 1, minNumberOfQuBits: 4)
        
        XCTAssertTrue((register1-register2).mostProbableIntegerValue() == 7)
        //in modular arithmetics, 2-21 mod 32 is 13 (-19 mod 32 = 32-19 = 13)
        XCTAssertTrue((register3-register4).mostProbableIntegerValue() == 13)
        XCTAssertTrue((register5-register6).mostProbableIntegerValue() == 535)
        XCTAssertTrue((register8-register7).mostProbableIntegerValue() == 0)
    }
    
    func testCanTeleportQuBitStateToAnotherQuBit() {
        let circuit = QuTeleportationCircuit()
        let input = QuBit(groundAmplitude: QuAmplitude(1.0/sqrt(2.0), 0.0), excitedAmplitude: QuAmplitude(0.0, -1.0/sqrt(2.0)))
        let output = circuit.teleport(input)
        XCTAssertTrue(try! QuMeasurer(input: output).entangledQuBits().last! == input)
        
        let output2 = try! circuit.transform(input: QuRegister(quBits: input, .grounded, .grounded))
        let qubits = try! QuMeasurer(input: output2).entangledQuBits()
        XCTAssertTrue(qubits[0].groundStateProbability == 1.0)
        XCTAssertTrue(qubits[1].groundStateProbability == 1.0)
        XCTAssertTrue(qubits[2] == input)
    }
    
    func testSimulationPerformance() {
        measure{
            self.testGrooverCircuitCanFindANumberUsingAnOracleWithAHighProbability()
        }
    }
    
    func testQFTPerformance() {
        measure {
            let gate = QuFTGate(numberOfInputs: 8)
            let input = QuRegister(numberOfQuBits: 8)
            let _ = try! gate.transform(input: input)
        }
    }
    
    func testComplexSimulationPerformance() {
        measure{
            let precision = 4
            let errorProbability = 0.1
            let maxAllowedError = 1.0/pow(2.0, Double(precision-1))
            
            let phase1 = 2.0/3.0
            let circuit1 = self.phaseEstimationCircuit(forRealPhase: phase1, precision: precision, errorProbability: errorProbability)
            let (estPhase1, _) = try! circuit1.estimatePhase(forOperatorInput: QuRegister(quBits: .excited))
            
            XCTAssertTrue(abs(estPhase1-phase1) <= maxAllowedError)
        }
    }
    
    func testSerializerPerformance() {
        let x = PauliXGate()
        let cNot = MultiControlMultiTargetControlledGate(numberOfControlInputs: 3, targetGate: ControlledNotGate())
        
        do {
            let oracleCircuit = QuCircuit(name: "Oracle-7", numberOfInputs: 5)
            try oracleCircuit.append(transformer: x, atTime: 0, forInputAtIndices: [0])
            try oracleCircuit.append(transformer: cNot, atTime: 1, forInputAtIndices: [0,1,2,3,4])
            try oracleCircuit.append(transformer: x, atTime: 2, forInputAtIndices: [0])
            
            let testCircuit = GroverCircuit(oracle: oracleCircuit)
            
            measure{
                let _ = QuCircuitSerializer.serialize(testCircuit)
            }
            
        }catch{
            XCTAssert(false)
        }
    }
    
    func testDeserializerPerformance() {
        let x = PauliXGate()
        let cNot = MultiControlMultiTargetControlledGate(numberOfControlInputs: 3, targetGate: ControlledNotGate())
        
        do {
            let oracleCircuit = QuCircuit(name: "Oracle-7", numberOfInputs: 5)
            try oracleCircuit.append(transformer: x, atTime: 0, forInputAtIndices: [0])
            try oracleCircuit.append(transformer: cNot, atTime: 1, forInputAtIndices: [0,1,2,3,4])
            try oracleCircuit.append(transformer: x, atTime: 2, forInputAtIndices: [0])
            
            let testCircuit = GroverCircuit(oracle: oracleCircuit)
            let serialized = QuCircuitSerializer.serialize(testCircuit)
            
            measure{
                let _ = try! QuCircuitSerializer.deserialize(serialized)
            }
            
        }catch{
            XCTAssert(false)
        }
    }
}
