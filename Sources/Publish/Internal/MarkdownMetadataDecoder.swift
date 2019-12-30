/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation

internal final class MarkdownMetadataDecoder: Decoder {
    var userInfo: [CodingUserInfoKey : Any] { [:] }
    let codingPath: [CodingKey]

    private let metadata: [String : String]
    private let dateFormatter: DateFormatter
    private lazy var keyedContainers = [ObjectIdentifier : Any]()

    init(metadata: [String : String],
         codingPath: [CodingKey] = [],
         dateFormatter: DateFormatter) {
        self.metadata = metadata
        self.codingPath = codingPath
        self.dateFormatter = dateFormatter
    }

    func container<T: CodingKey>(
        keyedBy type: T.Type
    ) throws -> KeyedDecodingContainer<T> {
        let typeID = ObjectIdentifier(type)

        if let cached = keyedContainers[typeID] {
            return KeyedDecodingContainer(cached as! KeyedContainer<T>)
        }

        let container = KeyedContainer<T>(
            metadata: metadata,
            codingPath: codingPath,
            dateFormatter: dateFormatter
        )

        keyedContainers[typeID] = container
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let prefix = codingPath.asPrefix(includingTrailingSeparator: false)

        guard let string = metadata[prefix] else {
            throw DecodingError.unkeyedContainerNotAvailable(at: codingPath)
        }

        return UnkeyedContainer(
            components: string.split(separator: ","),
            codingPath: codingPath
        )
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        let prefix = codingPath.asPrefix(includingTrailingSeparator: false)

        guard let string = metadata[prefix] else {
            throw DecodingError.singleValueContainerNotAvailable(at: codingPath)
        }

        return SingleValueContainer(value: string, codingPath: codingPath)
    }
}

private extension MarkdownMetadataDecoder {
    struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var allKeys: [Key] { keys.all() }

        let metadata: [String : String]
        let keys: KeyMap<Key>
        let codingPath: [CodingKey]
        let prefix: String
        let dateFormatter: DateFormatter

        init(metadata: [String : String],
             codingPath: [CodingKey],
             dateFormatter: DateFormatter) {
            self.metadata = metadata
            self.keys = KeyMap(raw: metadata.keys, codingPath: codingPath)
            self.codingPath = codingPath
            self.prefix = codingPath.asPrefix()
            self.dateFormatter = dateFormatter
        }

        func contains(_ key: Key) -> Bool {
            keys.contains(key)
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            false
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            try decode(key, transform: Bool.init)
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            try decode(key)
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            try decode(key, transform: Double.init)
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            try decode(key, transform: Float.init)
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            try decode(key, transform: Int.init)
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            try decode(key, transform: Int8.init)
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            try decode(key, transform: Int16.init)
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            try decode(key, transform: Int32.init)
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            try decode(key, transform: Int64.init)
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            try decode(key, transform: UInt.init)
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            try decode(key, transform: UInt8.init)
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            try decode(key, transform: UInt16.init)
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            try decode(key, transform: UInt32.init)
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            try decode(key, transform: UInt64.init)
        }

        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            if T.self == URL.self {
                return try decodeURL(forKey: key) as! T
            } else if T.self == Date.self {
                return try decodeDate(forKey: key) as! T
            }

            return try T(from: MarkdownMetadataDecoder(
                metadata: metadata,
                codingPath: codingPath.appending(key),
                dateFormatter: dateFormatter
            ))
        }

        func nestedContainer<T: CodingKey>(
            keyedBy type: T.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<T> {
            KeyedDecodingContainer(KeyedContainer<T>(
                metadata: metadata,
                codingPath: codingPath.appending(key),
                dateFormatter: dateFormatter
            ))
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            let string = try decode(key)

            return UnkeyedContainer(
                components: string.split(separator: ","),
                codingPath: codingPath.appending(key)
            )
        }

        func superDecoder() throws -> Decoder {
            MarkdownMetadataDecoder(
                metadata: metadata,
                codingPath: codingPath,
                dateFormatter: dateFormatter
            )
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            MarkdownMetadataDecoder(
                metadata: metadata,
                codingPath: codingPath.appending(key),
                dateFormatter: dateFormatter
            )
        }

        private func decode(_ key: Key) throws -> String {
            guard let string = metadata[prefix + key.stringValue] else {
                throw DecodingError.keyNotFound(key, DecodingError.Context(
                    codingPath: codingPath.appending(key),
                    debugDescription: """
                    No value found for key '\(key.stringValue)'.
                    """
                ))
            }

            return string
        }

        private func decode<T>(_ key: Key, transform: (String) -> T?) throws -> T {
            let string = try decode(key)

            guard let transformed = transform(string) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: self,
                    debugDescription: """
                    Could not convert '\(string)' into a value\
                    of type '\(String(describing: T.self))'.
                    """
                )
            }

            return transformed
        }

        private func decodeURL(forKey key: Key) throws -> URL {
            try URL.decode(from: decode(key), forKey: key, at: codingPath)
        }

        private func decodeDate(forKey key: Key) throws -> Date {
            try Date.decode(
                from: decode(key),
                forKey: key,
                at: codingPath,
                formatter: dateFormatter
            )
        }
    }

    struct UnkeyedContainer: UnkeyedDecodingContainer {
        var count: Int? { components.count }
        var isAtEnd: Bool { currentIndex == components.endIndex }

        let components: [Substring]
        let codingPath: [CodingKey]
        var currentIndex = 0

        mutating func decodeNil() throws -> Bool {
            false
        }

        mutating func decode(_ type: Bool.Type) throws -> Bool {
            try decodeNext(using: Bool.init)
        }

        mutating func decode(_ type: String.Type) throws -> String {
            try decodeNext()
        }

        mutating func decode(_ type: Double.Type) throws -> Double {
            try decodeNext(using: Double.init)
        }

        mutating func decode(_ type: Float.Type) throws -> Float {
            try decodeNext(using: Float.init)
        }

        mutating func decode(_ type: Int.Type) throws -> Int {
            try decodeNext(using: Int.init)
        }

        mutating func decode(_ type: Int8.Type) throws -> Int8 {
            try decodeNext(using: Int8.init)
        }

        mutating func decode(_ type: Int16.Type) throws -> Int16 {
            try decodeNext(using: Int16.init)
        }

        mutating func decode(_ type: Int32.Type) throws -> Int32 {
            try decodeNext(using: Int32.init)
        }

        mutating func decode(_ type: Int64.Type) throws -> Int64 {
            try decodeNext(using: Int64.init)
        }

        mutating func decode(_ type: UInt.Type) throws -> UInt {
            try decodeNext(using: UInt.init)
        }

        mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
            try decodeNext(using: UInt8.init)
        }

        mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
            try decodeNext(using: UInt16.init)
        }

        mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
            try decodeNext(using: UInt32.init)
        }

        mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
            try decodeNext(using: UInt64.init)
        }

        mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
            if T.self == URL.self {
                return try decodeNextAsURL() as! T
            }

            return try T(from: SingleValueDecoder(
                value: decodeNext(),
                codingPath: codingPath
            ))
        }

        mutating func nestedContainer<T: CodingKey>(
            keyedBy type: T.Type
        ) throws -> KeyedDecodingContainer<T> {
            throw DecodingError.valueNotFound(
                KeyedDecodingContainer<T>.self,
                DecodingError.Context(
                    codingPath: codingPath,
                    debugDescription: """
                    Cannot obtain a keyed container while decoding\
                    using an unkeyed metadata container.
                    """
                )
            )
        }

        mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            let components = try decodeNext().split(separator: ",")

            return UnkeyedContainer(
                components: components,
                codingPath: codingPath
            )
        }

        mutating func superDecoder() throws -> Decoder {
            UnkeyedDecoder(
                components: components,
                codingPath: codingPath
            )
        }

        private mutating func decodeNext() throws -> String {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(String.self,
                    DecodingError.Context(
                        codingPath: codingPath,
                        debugDescription: """
                        Index \(currentIndex) is out of bounds.
                        """
                    )
                )
            }

            let next = components[currentIndex]
            currentIndex += 1
            return next.trimmingCharacters(in: .whitespaces)
        }

        private mutating func decodeNextAsURL() throws -> URL {
            try URL.decode(from: decodeNext(), forKey: nil, at: codingPath)
        }

        private mutating func decodeNext<T>(using transform: (String) -> T?) throws -> T {
            let string = try decodeNext()

            guard let transformed = transform(string) else {
                throw DecodingError.dataCorruptedError(
                    in: self,
                    debugDescription: """
                    Could not convert '\(string)' into a value\
                    of type '\(String(describing: T.self))'.
                    """
                )
            }

            return transformed
        }
    }

    struct UnkeyedDecoder: Decoder {
        var userInfo: [CodingUserInfoKey : Any] { [:] }

        let components: [Substring]
        var codingPath: [CodingKey]

        func container<T: CodingKey>(keyedBy type: T.Type) throws -> KeyedDecodingContainer<T> {
            throw DecodingError.keyedContainerNotAvailable(
                at: codingPath,
                keyType: T.self
            )
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            UnkeyedContainer(components: components, codingPath: codingPath)
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            throw DecodingError.singleValueContainerNotAvailable(at: codingPath)
        }
    }

    struct SingleValueContainer: SingleValueDecodingContainer {
        let value: String
        let codingPath: [CodingKey]

        func decodeNil() -> Bool {
            false
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            try decode(using: Bool.init)
        }

        func decode(_ type: String.Type) throws -> String {
            value
        }

        func decode(_ type: Double.Type) throws -> Double {
            try decode(using: Double.init)
        }

        func decode(_ type: Float.Type) throws -> Float {
            try decode(using: Float.init)
        }

        func decode(_ type: Int.Type) throws -> Int {
            try decode(using: Int.init)
        }

        func decode(_ type: Int8.Type) throws -> Int8 {
            try decode(using: Int8.init)
        }

        func decode(_ type: Int16.Type) throws -> Int16 {
            try decode(using: Int16.init)
        }

        func decode(_ type: Int32.Type) throws -> Int32 {
            try decode(using: Int32.init)
        }

        func decode(_ type: Int64.Type) throws -> Int64 {
            try decode(using: Int64.init)
        }

        func decode(_ type: UInt.Type) throws -> UInt {
            try decode(using: UInt.init)
        }

        func decode(_ type: UInt8.Type) throws -> UInt8 {
            try decode(using: UInt8.init)
        }

        func decode(_ type: UInt16.Type) throws -> UInt16 {
            try decode(using: UInt16.init)
        }

        func decode(_ type: UInt32.Type) throws -> UInt32 {
            try decode(using: UInt32.init)
        }

        func decode(_ type: UInt64.Type) throws -> UInt64 {
            try decode(using: UInt64.init)
        }

        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            let decoder = SingleValueDecoder(
                value: value,
                codingPath: codingPath
            )

            return try T(from: decoder)
        }

        private func decode<T>(using transform: (String) -> T?) throws -> T {
            guard let transformed = transform(value) else {
                throw DecodingError.dataCorruptedError(
                    in: self,
                    debugDescription: """
                    Could not convert '\(value)' into a value\
                    of type '\(String(describing: T.self))'.
                    """
                )
            }

            return transformed
        }
    }

    struct SingleValueDecoder: Decoder {
        var userInfo: [CodingUserInfoKey : Any] { [:] }

        let value: String
        let codingPath: [CodingKey]

        func container<T: CodingKey>(
            keyedBy type: T.Type
        ) throws -> KeyedDecodingContainer<T> {
            throw DecodingError.keyedContainerNotAvailable(
                at: codingPath,
                keyType: T.self
            )
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw DecodingError.unkeyedContainerNotAvailable(at: codingPath)
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            SingleValueContainer(
                value: value,
                codingPath: codingPath
            )
        }
    }

    final class KeyMap<Key: CodingKey> {
        private typealias Evaluated = (array: [Key], set: Set<String>)

        private let raw: Dictionary<String, String>.Keys
        private let codingPath: [CodingKey]
        private var evaluated: Evaluated?

        init(raw: Dictionary<String, String>.Keys,
             codingPath: [CodingKey]) {
            self.raw = raw
            self.codingPath = codingPath
        }

        func all() -> [Key] {
            evaluateIfNeeded().array
        }

        func contains(_ key: Key) -> Bool {
            evaluateIfNeeded().set.contains(key.stringValue)
        }

        private func evaluateIfNeeded() -> Evaluated {
            if let evaluated = evaluated {
                return evaluated
            }

            var evaluated: Evaluated = ([], [])

            for rawKey in raw {
                let components = rawKey.split(separator: ".")

                for (index, component) in components.enumerated() {
                    guard codingPath.count > index else {
                        let stringKey = String(component)

                        if let key = Key(stringValue: stringKey) {
                            evaluated.array.append(key)
                            evaluated.set.insert(stringKey)
                        }

                        break
                    }
                }
            }

            self.evaluated = evaluated
            return evaluated
        }
    }
}

private extension Array where Element == CodingKey {
    func asPrefix(includingTrailingSeparator addTrailingSeparator: Bool = true) -> String {
        var isFirstKey = true

        let string = reduce(into: "") { string, key in
            if isFirstKey {
                isFirstKey = false
            } else {
                string.append(".")
            }

            string.append(key.stringValue)
        }

        guard !string.isEmpty, addTrailingSeparator else {
            return string
        }

        return string.appending(".")
    }
}

private extension URL {
    static func decode(from string: String,
                       forKey key: CodingKey?,
                       at codingPath: [CodingKey]) throws -> Self {
        guard let url = URL(string: string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: key.map(codingPath.appending) ?? codingPath,
                    debugDescription: "Invalid URL string."
                )
            )
        }

        return url
    }
}

private extension Date {
    static func decode(from string: String,
                       forKey key: CodingKey?,
                       at codingPath: [CodingKey],
                       formatter: DateFormatter) throws -> Self {
        guard let date = formatter.date(from: string) else {
            let formatDescription = formatter.dateFormat.map {
                " Expected format: \($0)."
            }

            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: key.map(codingPath.appending) ?? codingPath,
                    debugDescription: """
                    Invalid date string.\(formatDescription ?? "")
                    """
                )
            )
        }

        return date
    }
}

private extension DecodingError {
    static func keyedContainerNotAvailable<T: CodingKey>(
        at path: [CodingKey],
        keyType: T.Type
    ) -> Self {
        .valueNotFound(
            KeyedDecodingContainer<T>.self,
            DecodingError.Context(
                codingPath: path,
                debugDescription: """
                Cannot obtain a keyed decoding container within this context.
                """
            )
        )
    }

    static func unkeyedContainerNotAvailable(at path: [CodingKey]) -> Self {
        .valueNotFound(
            UnkeyedDecodingContainer.self,
            DecodingError.Context(
                codingPath: path,
                debugDescription: """
                Cannot obtain an unkeyed decoding container within this context.
                """
            )
        )
    }

    static func singleValueContainerNotAvailable(at path: [CodingKey]) -> Self {
        .valueNotFound(
            SingleValueDecodingContainer.self,
            DecodingError.Context(
                codingPath: path,
                debugDescription: """
                Cannot obtain a single value decoding container within this context.
                """
            )
        )
    }
}
