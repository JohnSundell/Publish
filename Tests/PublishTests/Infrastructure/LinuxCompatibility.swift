/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest

public enum Linux {}

public extension Linux {
    typealias TestCase = (testCaseClass: XCTestCase.Type, allTests: TestManifest)
    typealias TestManifest = [(String, TestRunner)]
    typealias TestRunner = (XCTestCase) throws -> Void
    typealias TestList<T: XCTestCase> = [(String, Test<T>)]
    typealias Test<T: XCTestCase> = (T) -> () throws -> Void
}

internal extension Linux {
    static func makeTestCase<T: XCTestCase>(using list: TestList<T>) -> TestCase {
        let manifest: TestManifest = list.map { name, function in
            (name, { type in
                try function(type as! T)()
            })
        }

        return (T.self, manifest)
    }
}

#if canImport(ObjectiveC)
internal final class LinuxVerificationTests: XCTestCase {
    func testAllTestsRunOnLinux() {
        var totalLinuxTestCount = 0

        for testCase in allTests() {
            let type = testCase.testCaseClass

            let testNames: [String] = type.defaultTestSuite.tests.map { test in
                let components = test.name.components(separatedBy: .whitespaces)
                return components[1].replacingOccurrences(of: "]", with: "")
            }

            let linuxTestNames = Set(testCase.allTests.map { $0.0 })

            for name in testNames {
                if !linuxTestNames.contains(name) {
                    XCTFail("""
                    \(type).\(name) does not run on Linux.
                    Please add it to \(type).allTests.
                    """)
                }
            }

            totalLinuxTestCount += linuxTestNames.count
        }

        XCTAssertEqual(
            XCTestSuite.default.testCaseCount - 1,
            totalLinuxTestCount,
            """
            Linux and Apple Platforms test counts are not equal.
            Perhaps you added a new test case class?
            If so, you need to add it in XCTestManifests.swift.
            """
        )
    }
}
#endif
