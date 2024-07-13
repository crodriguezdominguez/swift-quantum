//
//  QuantumGatesTests.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 1/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import XCTest
import SwiftQuantum

class QuantumGatesTests : XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testQuBitSetterChangesAQuBitToASpecificState() {
        let setter0 = QuBitSetter()
        let setter1 = QuBitSetter(grounded: false)
        
        XCTAssertTrue(setter0.transform(input: .excited) == .grounded)
        XCTAssertTrue(setter0.transform(input: .grounded) == .grounded)
        
        XCTAssertTrue(setter1.transform(input: .excited) == .excited)
        XCTAssertTrue(setter1.transform(input: .grounded) == .excited)
    }
    
    func testHadamardGatesCanCreateRegistersWithAllStatesWithTheSameProbability() {
        let register = QuRegister(hadamardForNumberOfQuBits: 3)
        let probabilisticMap = register.measure()
        
        XCTAssertTrue(probabilisticMap.count == 8)
        
        let probability = probabilisticMap.values.first!
        for p in probabilisticMap.values {
            XCTAssertTrue(probability == p)
        }
    }
    
    func testHadamardGatesProduceRandomNumbers() {
        let register = QuRegister(hadamardForNumberOfQuBits: 3)
        let testing = register.mostProbableIntegerValue()
        var appearance = 0
        let amountOfTests = 1000
        for _ in 0..<amountOfTests {
            if register.mostProbableIntegerValue() == testing {
                appearance += 1
            }
        }
        let prob = Double(appearance) / Double(amountOfTests)
        XCTAssertTrue(prob < 0.25) //it should be around 0.125 with sufficient tests, but 0.25 is good enough randomness
    }
    
    func testTwoSquareRootOfNotGatesProduceANotGate() {
        let quBit = QuBit(groundAmplitude: 1.0.i, excitedAmplitude: .zero)
        do{
            let output1 = SquareRootOfNotGate().transform(input: quBit)
            XCTAssertTrue(output1.groundStateProbability =~ output1.excitedStateProbability)
            
            let output2 = SquareRootOfNotGate().transform(input: output1)
            let measure2 = try QuMeasurer(input: output2.matrixRepresentation()).mostProbableStates().states.first!
            
            if case .excited(1.0) = measure2 {
                XCTAssert(true)
            }
            else {
                XCTAssert(false)
            }
            
        }catch{
            XCTAssert(false)
        }
    }
    
    func testACompiledGateProducesTheSameResultAsAChainTransformationUsingThoseGates() {
        let quBit = QuBit(groundAmplitude: 1.0.i, excitedAmplitude: .zero)
        
        do {
            let HQuBit1 = HadamardGate().transform(input: quBit)
            let ZQuBit = PauliZGate().transform(input: HQuBit1)
            let HQuBit2 =  HadamardGate().transform(input: ZQuBit)
            
            let compiledGate = CompiledGate(name: "HZH", gates: [HadamardGate(), PauliZGate(), HadamardGate()])!
            let result = try compiledGate.transform(input: quBit)
            
            XCTAssertTrue(HQuBit2.matrixRepresentation() == result)
            
        }catch{
            XCTAssert(false)
        }
    }
    
    func testTwoSquareRootOfSwapGatesProduceASwapGate() {
        let quBit1 = QuBit.grounded
        let quBit2 = QuBit(groundAmplitude: .zero, excitedAmplitude: 1.0.i)
        let register = QuRegister(quBits: quBit1, quBit2)
        
        do {
            let compiledGate = CompiledGate(name: "√Swap+√Swap", gates: [SquareRootOfSwapGate(), SquareRootOfSwapGate()])!
            let swapped1 = try compiledGate.transform(input: register)
            let swapped2 = try SwapGate().transform(input: register)
            
            XCTAssertTrue(swapped1 == swapped2)
        }catch{
            XCTAssert(false)
        }
    }
    
    func testZIsEqualToPhaseOfPi() {
        let quBit1 = QuBit(groundAmplitude: .zero, excitedAmplitude: 1.0.i)
        let quBit2 = QuBit(groundAmplitude: .zero, excitedAmplitude: 1.0.i)
        
        let pauliZTransformedQuBit = PauliZGate().transform(input: quBit1)
        let phasePiTransformedQuBit = PhaseGate(parameter: .pi).transform(input: quBit2)
        
        XCTAssertTrue(pauliZTransformedQuBit == phasePiTransformedQuBit)
    }
    
    func testAPauliXGateProducesAClassicalNot() {
        let quBit = QuBit(groundAmplitude: .zero, excitedAmplitude: 1.0.i)
        
        let transformed1 = PauliXGate().transform(input: quBit)
        XCTAssertTrue(transformed1.groundStateProbability == 1.0)
        
        let transformed2 = PauliXGate().transform(input: transformed1)
        XCTAssertTrue(transformed2.excitedStateProbability == 1.0)
        
        let quBit2 = QuBit(groundAmplitude: .one, excitedAmplitude: .zero)
        
        let transformed3 = PauliXGate().transform(input: quBit2)
        XCTAssertTrue(transformed3.groundStateProbability == 0.0 && transformed3.excitedStateProbability == 1.0)
        
        let transformed4 = PauliXGate().transform(input: transformed3)
        XCTAssertTrue(transformed4.groundStateProbability == 1.0 && transformed4.excitedStateProbability == 0.0)
    }
    
    func testHXHIsEqualToZ() {
        let quBit = QuBit(groundAmplitude: .zero, excitedAmplitude: 1.0.i)
        
        do {
            let pauliZTransformedQuBit = PauliZGate().transform(input: quBit)
            
            let compiledGate = CompiledGate(name: "HXH", gates: [HadamardGate(), PauliXGate(), HadamardGate()])!
            let HXHMatrix = try compiledGate.transform(input: quBit)
            let HXHQuBit = QuBit(matrix:HXHMatrix)!
            
            XCTAssertTrue(pauliZTransformedQuBit == HXHQuBit)
        }catch{
            XCTAssert(false)
        }
    }
    
    func testXTransformationMatrixIsEqualToItsCircuitImplementation() {
        let x = PauliXGate()
        XCTAssertTrue(x.transformationMatrix == x.quCircuit.transformationMatrix)
    }
    
    func testMultipleControlInputsControlledGateWithTwoInputsIsEqualToOneUniversalControlledGate() {
        let quBit1 = QuBit.grounded
        let quBit2 = QuBit(groundAmplitude: .zero, excitedAmplitude: 1.0.i)
        let quBit3 = QuBit(groundAmplitude: 1.0.i, excitedAmplitude: .zero)
        
        let gate1 = MultiControlMultiTargetControlledGate(numberOfControlInputs: 2, targetGate: PauliZGate())
        let gate2 = UniversalCCGate(gate: PauliZGate())
        
        let gate3 = UniversalControlledGate(gate: HadamardGate())
        let gate4 = MultiControlMultiTargetControlledGate(numberOfControlInputs: 1, targetGate: HadamardGate())
        
        do {
            let result1 = try gate1.transform(input: QuRegister(quBits: quBit1, quBit2, quBit3))
            let result2 = gate2.transform(input: (quBit1, quBit2, quBit3))
            
            XCTAssertTrue(gate1.transformationMatrix == gate2.transformationMatrix)
            XCTAssertTrue(result1 == result2)
            
            let result3 = gate3.transform(input: (quBit1, quBit3))
            let result4 = try gate4.transform(input: QuRegister(quBits: quBit1, quBit3))
            
            XCTAssertTrue(gate3.transformationMatrix == gate4.transformationMatrix)
            XCTAssertTrue(result3 == result4)
        }
        catch {
            XCTAssert(false)
        }
    }
    
    func testQuBitOperatorsWorksAsExpected() {
        //NOT
        XCTAssertTrue(~QuBit.grounded == QuBit.excited)
        XCTAssertTrue(~QuBit.excited == QuBit.grounded)
        
        //XOR
        XCTAssertTrue(QuBit.grounded ^ QuBit.grounded == QuBit.grounded)
        XCTAssertTrue(QuBit.grounded ^ QuBit.excited == QuBit.excited)
        XCTAssertTrue(QuBit.excited ^ QuBit.grounded == QuBit.excited)
        XCTAssertTrue(QuBit.excited ^ QuBit.excited == QuBit.grounded)
        
        //AND
        XCTAssertTrue(QuBit.grounded & QuBit.grounded == QuBit.grounded)
        XCTAssertTrue(QuBit.grounded & QuBit.excited == QuBit.grounded)
        XCTAssertTrue(QuBit.excited & QuBit.grounded == QuBit.grounded)
        XCTAssertTrue(QuBit.excited & QuBit.excited == QuBit.excited)
        
        //OR
        XCTAssertTrue(QuBit.grounded | QuBit.grounded == QuBit.grounded)
        XCTAssertTrue(QuBit.grounded | QuBit.excited == QuBit.excited)
        XCTAssertTrue(QuBit.excited | QuBit.grounded == QuBit.excited)
        XCTAssertTrue(QuBit.excited | QuBit.excited == QuBit.excited)
    }
    
    func testBlochSphereCoordinatesAreCorrectlyGenerated() {
        let maxAllowedError = Double.ulpOfOne*2.0
        
        let (x0, y0, z0) = QuAnalyzer.blochSphereCoordinates(.excited)
        XCTAssertTrue(x0 < maxAllowedError && y0 < maxAllowedError && abs(z0+1.0) < maxAllowedError)
        
        let (x1, y1, z1) = QuAnalyzer.blochSphereCoordinates(.grounded)
        XCTAssertTrue(x1 < maxAllowedError && y1 < maxAllowedError && abs(z1-1.0) < maxAllowedError)
        
        let complexSqrt = QuAmplitude(0.5.squareRoot(), 0.0)
        let (x2, y2, z2) = QuAnalyzer.blochSphereCoordinates(QuBit(groundAmplitude: complexSqrt, excitedAmplitude: complexSqrt))
        XCTAssertTrue(abs(x2-1.0) < maxAllowedError && y2 < maxAllowedError && z2 < maxAllowedError)
        
        let (x3, y3, z3) = QuAnalyzer.blochSphereCoordinates(QuBit(groundAmplitude: complexSqrt, excitedAmplitude: -complexSqrt))
        XCTAssertTrue(abs(x3+1.0) < maxAllowedError && y3 < maxAllowedError && z3 < maxAllowedError)
        
        let (x4, y4, z4) = QuAnalyzer.blochSphereCoordinates(QuBit(groundAmplitude: complexSqrt, excitedAmplitude: complexSqrt.i))
        XCTAssertTrue(x4 < maxAllowedError && abs(y4-1.0) < maxAllowedError && z4 < maxAllowedError)
        
        let (x5, y5, z5) = QuAnalyzer.blochSphereCoordinates(QuBit(groundAmplitude: complexSqrt, excitedAmplitude: -complexSqrt.i))
        XCTAssertTrue(x5 < maxAllowedError && abs(y5+1.0) < maxAllowedError && z5 < maxAllowedError)
    }
}
