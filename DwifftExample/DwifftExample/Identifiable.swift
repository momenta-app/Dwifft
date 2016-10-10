//
//  Identifiable.swift
//  Momenta
//
//  Created by Alexander Griekspoor on 22/07/16.
//  Copyright © 2016 Momenta BV. All rights reserved.

import Foundation

/// The `Identifiable` protocol adds the ability to identify the type through a unique identifier.
/// - Requires: the presence of a stored property `uuid` in any class supporting this protocol.

public protocol Identifiable  {
    
    /// A unique identifier.
    var uuid : String { get }

}