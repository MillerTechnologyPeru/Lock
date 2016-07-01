//
//  Key.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/22/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import SwiftFoundation

public struct Key: Equatable {
    
    public let identifier: UUID
    
    public let data: KeyData
    
    public let permission: Permission
    
    /// The name of the key.
    ///
    /// - Note: Not applicable for Owner keys. 
    public let name: Name?
    
    public init(identifier: UUID = UUID(), name: Name? = nil, data: KeyData = KeyData(), permission: Permission = .owner) {
        
        self.identifier = identifier
        self.name = name
        self.data = data
        self.permission = permission
    }
}

public func == (lhs: Key, rhs: Key) -> Bool {
    
    return lhs.identifier == rhs.identifier
        && lhs.data == rhs.data
        && lhs.permission == rhs.permission
}

// MARK: - Supporting Types

public extension Key {
    
    /// 64 byte String name.
    public struct Name: Equatable, RawRepresentable, DataConvertible, CustomStringConvertible {
        
        public static let maxLength = 64
        
        public let rawValue: String
        
        public init?(rawValue: String) {
            
            guard rawValue.utf8.count <= Name.maxLength
                && rawValue.isEmpty == false
                else { return nil }
            
            self.rawValue = rawValue
        }
        
        public init?(data: Data) {
            
            guard let string = String(UTF8Data: data)
                where string.isEmpty == false
                && data.bytes.count <= Name.maxLength
                else { return nil }
            
            self.rawValue = string
        }
        
        @inline(__always)
        public func toData() -> Data {
            
            return rawValue.toUTF8Data()
        }
        
        public var description: String {
            
            return rawValue
        }
    }
}
