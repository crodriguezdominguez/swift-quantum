//
//  Integer+BinaryExtensions.swift
//  QuantumComputing
//
//  Created by Carlos Rodríguez Domínguez on 4/7/16.
//  Copyright © 2016 Everyware Technologies. All rights reserved.
//

import Foundation

extension FixedWidthInteger {
    func binaryRepresentation(numberOfBits:Int) -> String {
        var binary = String(self, radix: 2)
        if binary.count < numberOfBits {
            for _ in binary.count..<numberOfBits {
                binary = "0"+binary
            }
        }
        
        return binary
    }
}

