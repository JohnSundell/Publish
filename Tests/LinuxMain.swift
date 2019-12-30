/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest

import PublishTests

var tests = [XCTestCaseEntry]()
tests += PublishTests.allTests()
XCTMain(tests)
