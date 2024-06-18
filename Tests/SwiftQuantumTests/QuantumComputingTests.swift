//
//  QuantumComputingTests.swift
//  QuantumComputingTests
//
//  Created by Carlos Rodríguez Domínguez on 30/6/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import XCTest
import SwiftQuantum

class QuantumComputingTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAQuBitWithGroundAmplitudeOf1HasAGroundStateOf1() {
        var qbit1 = QuBit(groundAmplitude: .one, excitedAmplitude: .zero)
        if case .grounded(let state) = qbit1.measure() {
            XCTAssertTrue(state =~ 1.0)
        }
        else{
            XCTAssert(false)
        }
        
        var qbit2 = QuBit(groundAmplitude: 1.0.i, excitedAmplitude: .zero)
        if case .grounded(let state) = qbit2.measure() {
            XCTAssertTrue(state =~ 1.0)
        }
        else{
            XCTAssert(false)
        }
    }
    
    func testAQuBitWithExcitedAmplitudeOf1HasAnExcitedStateOf1() {
        var qbit1 = QuBit.excited
        if case .excited(let state) = qbit1.measure() {
            XCTAssertTrue(state =~ 1.0)
        }
        else{
            XCTAssert(false)
        }
        
        var qbit2 = QuBit(groundAmplitude: .zero, excitedAmplitude: 1.0.i)
        if case .excited(let state) = qbit2.measure() {
            XCTAssertTrue(state =~ 1.0)
        }
        else{
            XCTAssert(false)
        }
    }
    
    func testQuBitIsNormalized() {
        let qbit1 = QuBit(groundAmplitude: 1.0/Double.sqrt(2.0), excitedAmplitude: -1.0/Double.sqrt(2.0))
        
        XCTAssertTrue(qbit1.isNormalized)
        
        let qbit2 = QuBit(groundAmplitude: 1.0/Double.sqrt(3.0), excitedAmplitude: 1.0/Double.sqrt(2.0))
        
        XCTAssertFalse(qbit2.isNormalized)
    }
    
    func testAfterAMeasurementAQuBitKeepsACoherentState() {
        var qbit = QuBit(groundAmplitude: 1.0/Double.sqrt(2.0), excitedAmplitude: 1.0/Double.sqrt(2.0))
        let state = qbit.measure()
        
        let isExcited:Bool
        if case .excited(_) = state {
            isExcited = true
        }
        else if case .grounded(_) = state {
            isExcited = false
        }
        else{
            XCTAssert(false)
            return
        }
        
        for _ in 0..<1000 {
            let state = qbit.measure()
            
            if case .excited(let m) = state , !isExcited || m != 1.0 {
                XCTAssert(false)
            }
            else if case .grounded(let m) = state , isExcited || m != 1.0 {
                XCTAssert(false)
            }
            else if case .undefined = state {
                XCTAssert(false)
            }
        }
    }
    
    func testARegisterWith3QuBitsHas8States() {
        let qbit1 = QuBit(groundAmplitude: 1.0/Double.sqrt(2.0), excitedAmplitude: 1.0/Double.sqrt(2.0))
        let qbit2 = QuBit(groundAmplitude: -1.0/Double.sqrt(2.0), excitedAmplitude: 1.0/Double.sqrt(2.0))
        let qbit3 = QuBit(groundAmplitude: 1.0/Double.sqrt(2.0), excitedAmplitude: -1.0/Double.sqrt(2.0))
        
        let register = QuRegister(quBits: qbit1, qbit2, qbit3)
        XCTAssertTrue(register.countCodifiedStates == 8)
    }
    
    func testARegisterCanContainAUInt() {
        let register1 = QuRegister(fromNumber: 37) //odd
        XCTAssertTrue(register1.mostProbableIntegerValue() == 37)
        
        let register2 = QuRegister(fromNumber: 18) //even
        XCTAssertTrue(register2.mostProbableIntegerValue() == 18)
        
        let register3 = QuRegister(fromNumber: 0) //zero
        XCTAssertTrue(register3.mostProbableIntegerValue() == 0)
        
        let register4 = QuRegister(fromNumber: UInt32.max) //big number
        XCTAssertTrue(register4.mostProbableIntegerValue() == UInt32.max)
    }
    
    func testInARegisterWith3QuBitsAllStatesHaveTheSameProbability() {
        let qbit1 = QuBit(groundAmplitude: 1.0/Double.sqrt(2.0), excitedAmplitude: 1.0/Double.sqrt(2.0))
        let qbit2 = QuBit(groundAmplitude: -1.0/Double.sqrt(2.0), excitedAmplitude: 1.0/Double.sqrt(2.0))
        let qbit3 = QuBit(groundAmplitude: 1.0/Double.sqrt(2.0), excitedAmplitude: -1.0/Double.sqrt(2.0))
        
        let register = QuRegister(quBits: qbit1, qbit2, qbit3)
        let probabilisticMap = QuMeasurer(input: register).probabilisticMap()
        
        XCTAssertTrue(probabilisticMap.count == 8)
        
        let probability = probabilisticMap.values.first!
        for p in probabilisticMap.values {
            XCTAssertTrue(probability == p)
        }
    }
    
    func testTensorProductWorksAsExpected() {
        let m1 = QuAmplitudeMatrix([[1.0, 2.0],[3.0, 4.0]])
        let m2 = QuAmplitudeMatrix([[0.0, 5.0],[6.0, 7.0]])
        let result = tensorProduct(m1, m2)
        let testMatrix = QuAmplitudeMatrix([[0.0, 5.0, 0.0, 10.0],
                                 [6.0, 7.0, 12.0, 14.0],
                                 [0.0, 15.0, 0.0, 20.0],
                                 [18.0, 21.0, 24.0, 28.0]])
        
        XCTAssertTrue(result == testMatrix)
    }
    
    func testMatrixPowWorksAsExpected() {
        let m = QuAmplitudeMatrix([[1.0, 2.0],[3.0, 4.0]])
        let result1 = try! pow(m, exponent: 3)
        let testMatrix1 = QuAmplitudeMatrix([[37.0, 54.0], [81.0, 118.0]])
        
        XCTAssertTrue(result1 == testMatrix1)
        
        let result2 = try! pow(m, exponent: 0)
        let testMatrix2 = QuAmplitudeMatrix.identity(size: 2)
        
        XCTAssertTrue(result2 == testMatrix2)
        
        let result3 = try! pow(m, exponent: 1)
        
        XCTAssertTrue(result3 == m)
    }
}
