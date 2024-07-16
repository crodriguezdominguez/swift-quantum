//
//  QuantumAlgorithmsTests.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 29/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import XCTest
import SwiftQuantum

class QuantumAlgorithmsTests : XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testShorAlgorithmCanDecomposeANumberInPrimeFactors() {
        do {
            var result:[Int]? = nil
            repeat {
                result = try shorAlgorithm(77)
            } while result == nil
            
            XCTAssertTrue(result!.contains(11) && result!.contains(7))
        } catch {
            XCTAssert(false)
        }
    }
    
    fileprivate func shorAlgorithm(_ N:Int) throws -> [Int]? {
        if N % 2 == 0 {
            throw NSError(domain: "Shor's algorithm", code: 100, userInfo: [NSLocalizedDescriptionKey: "Numbers must be odd"])
        }
        
        if testPrime(N) {
            throw NSError(domain: "Shor's algorithm", code: 101, userInfo: [NSLocalizedDescriptionKey: "Input number is prime"])
        }
        
        if testPrimePower(N) {
            throw NSError(domain: "Shor's algorithm", code: 101, userInfo: [NSLocalizedDescriptionKey: "Input number is a power of a prime"])
        }
        
        // Find a number x relatively prime to n
        var x:Int = 0
        repeat {
            x = Int.random(in: 0..<N)
        } while(gcd(N,x) > 1 || x < 2)
        
        let L = Int(ceil(log2(Double(N))))
        var register = QuRegister(numberOfQuBits: L)
        
        //let width = 2*L+2 // commonly seen case
        let width = L // basic case, but ~25% chance of measuring 0 for 15
        
        register = HadamardGate().transform(input: register)
        register = modularExp(x: x, n: N, register: register)
        
        let matrix = try! QuFTGate(numberOfInputs: register.count).transform(input: register)
        var result = try! Int(QuMeasurer(input: matrix).mostProbableIntegerValue().integer)
        
        if result == 0 { //invalid case
            return nil
        }
        
        var denom = 1 << width
        fractionExpansion(&result, &denom)
        
        print("Fractional approximation is \(result)/\(denom).")
        
        if denom % 2 == 1 && 2*denom < (1<<width) { // Odd denominator: we try to expand by 2...
            denom *= 2
        }
        
        if denom % 2 == 1 { //odd period: invalid case
            return nil
        }
        
        print("Possible period is \(denom).")
        
        var factor = Int(pow(Double(x),Double(denom/2)))
        let factor1 = gcd(N, factor + 1)
        let factor2 = gcd(N, factor - 1)
        factor = max(factor1, factor2)
        
        if factor < N && factor > 1 {
            print("\(N) = \(factor) * \(N/factor)")
            return [factor, N/factor]
        }
        else { // could not determine factors
            return nil
        }
    }
    
    fileprivate func modularExp(x:Int, n number:Int, register:QuRegister) -> QuRegister {
        let count = Int(register.countCodifiedStates)
        var matrix = QuAmplitudeMatrix(rows: count, columns: 1, repeatedValue: 0.0)
        
        for i in 0..<count {
            matrix[i, 0] = QuAmplitude(0.0, Double(modularPowSimple(x, i, number)))
        }
        
        return try! QuMeasurer(input: matrix).mostProbableRegisterOutput()
    }
    
    fileprivate func modularPowSimple(_ b:Int, _  e:Int, _ n:Int) -> Int {
        var res = 1
        
        for _ in 0..<e {
            res = (res*b) % n
        }
        
        return res
    }

    fileprivate func testPrime(_ n:Int) -> Bool {
        if n<=1 {
            return false
        }
        
        for i in 2...Int(floor(sqrt(Double(n)))) {
            if n % i == 0 {
                return false
            }
        }
        
        return true
    }
    
    fileprivate func testPrimePower(_ n:Int) -> Bool {
        var i=2
        var f=0
        while i<=Int(floor(sqrt(Double(n)))) && f==0 {
            if n % i == 0 {
                f=i
            }
            i += 1
        }
        
        for k in 2...Int(floor(log(Double(n))/log(Double(f)))) {
            if Int(pow(Double(f), Double(k))) == n {
                return true
            }
        }
        
        return false
    }
    
    fileprivate func fractionExpansion(_ num:inout Int, _ denom:inout Int) {
        let orig_denom = denom
        let f = Double(num)/Double(orig_denom)
            
        var g = f
        var num1 = 1
        var num2 = 0
        var denom1 = 0
        var denom2 = 1
        var i = 0
        
        let test = 1.0 / (2.0 * Double(orig_denom))
        let CFE_STEP = 0.000005
        
        var frac = 0.0
        
        repeat {
            i = Int(g+CFE_STEP)
            g -= Double(i)-CFE_STEP
            g = 1.0 / g
            
            if i * denom1 + denom2 > orig_denom {
                break
            }
            
            num = i * num1 + num2
            denom = i * denom1 | denom2
            num2 = num1
            denom2 = denom1
            num1 = num
            denom1 = denom
            
            frac = abs(Double(num)/Double(denom))
            
        } while (frac - f) > test
    }
    
    fileprivate func gcd(_ a:Int, _ b:Int) -> Int {
        var a = a
        var b = b
        while b != 0 {
            let t = b
            b = a % b
            a = t
        }
        return a
    }
    
    func testShorAlgorithmPerformance() {
        measure { 
            let _ = try! self.shorAlgorithm(21)
        }
    }
}
