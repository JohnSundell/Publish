/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

/// Closure type used to implement content mutations.
public typealias Mutations<T> = (inout T) throws -> Void
