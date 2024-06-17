//
//  SparseArray.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 27/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

internal struct SparseArray : Collection, Equatable {
    public func index(after i: Int) -> Int {
        return i+1
    }

    var contents = [Int:QuAmplitude]()
    let count: Int
    let startIndex = 0
    let endIndex: Int
    fileprivate(set) var defaultValue: QuAmplitude
    
    init<T : Collection>(_ contents:T) where T.Iterator.Element == QuAmplitude {
        self.count = Int(contents.count)
        self.endIndex = self.count
        
        self.defaultValue = contents.first!
        
        //move collection contents to self
        for (idx, value) in contents.enumerated() {
            self[idx] = value
        }
        
        if shouldRecompress() {
            recompress()
        }
    }
    
    init(count:Int, defaultValue:QuAmplitude) {
        self.count = count
        self.endIndex = count
        self.defaultValue = defaultValue
    }
    
    @inline(__always) func denseRepresentation() -> [QuAmplitude] {
        return Array(self)
    }
    
    subscript(idx:Int) -> QuAmplitude {
        get {
            return contents[idx] ?? defaultValue
        }
        set {
            assert(idx < self.count, "The index is out of bounds")
            
            guard newValue != defaultValue else {
                self.contents.removeValue(forKey: idx)
                return
            }
            
            self.contents[idx] = newValue
        }
    }
    
    subscript(indices:CountableRange<Int>) -> [QuAmplitude] {
        get {
            var result = [QuAmplitude](repeating: self[indices.first!], count: indices.count)
            for (k, index) in indices.enumerated() {
                result[k] = self[index]
            }
            return result
        }
        set {
            assert(indices.count == newValue.count, "The size of the input array must be equal to the range span")
            
            for (k, index) in indices.enumerated() {
                self[index] = newValue[k]
            }
        }
    }
    
    func shouldRecompress() -> Bool {
        return self.contents.count == self.count
    }
    
    mutating func recompress() {
        guard self.contents.count > 0 else {
            return
        }
        
        var counts = [Int:Int](minimumCapacity:self.count)
        
        for key in self.contents.keys {
            counts[key] = (counts[key] ?? 0) + 1
        }
        
        let newDefault = self.contents[counts.max(by: { (el1, el2) in el1.1 > el2.1 })!.0]!
        
        if newDefault != self.defaultValue {
            for k in 0..<self.count {
                let ampl = self.contents[k]
                if ampl == nil {
                    self.contents[k] = self.defaultValue
                }
                else if abs(ampl! - newDefault) <= Double.ulpOfOne {
                    self.contents.removeValue(forKey: k)
                }
            }
            
            self.defaultValue = newDefault
        }
    }
}

func ==(lhs:SparseArray, rhs:SparseArray) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    
    for k in 0..<lhs.count {
        if lhs[k] !~ rhs[k] {
            return false
        }
    }
    
    return true
}
