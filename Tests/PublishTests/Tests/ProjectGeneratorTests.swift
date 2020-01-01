/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
@testable import PublishCLICore

final class ProjectGeneratorTests: PublishTestCase {

    func testMakeSiteName() {
        XCTAssertEqual(ProjectGenerator.makeSiteName(folderName: "Name"), "Name")
    }
    
    func testMakeSiteNameFromLowercasedFolderName() {
        XCTAssertEqual(ProjectGenerator.makeSiteName(folderName: "name"), "Name")
    }
    
    func testMakeSiteNameFromCamelCaseFolderName() {
        XCTAssertEqual(ProjectGenerator.makeSiteName(folderName: "CamelCaseName"), "CamelCaseName")
    }
    
    func testMakeSiteNameFromFolderNameWithNonLetters() {
        XCTAssertEqual(ProjectGenerator.makeSiteName(folderName: "My website 1"), "Mywebsite")
    }
    
    func testMakeSiteNameFromDigitsOnlyFolderName() {
        XCTAssertEqual(ProjectGenerator.makeSiteName(folderName: "1"), ProjectGenerator.defaultSiteName)
    }
}

extension ProjectGeneratorTests {
    static var allTests: Linux.TestList<ProjectGeneratorTests> {
        [
            ("testMakeSiteName", testMakeSiteName),
            ("testMakeSiteNameFromLowercasedFolderName", testMakeSiteNameFromLowercasedFolderName),
            ("testMakeSiteNameFromCamelCaseFolderName", testMakeSiteNameFromCamelCaseFolderName),
            ("testMakeSiteNameFromFolderNameWithNonLetters", testMakeSiteNameFromFolderNameWithNonLetters),
            ("testMakeSiteNameFromDigitsOnlyFolderName", testMakeSiteNameFromDigitsOnlyFolderName)
        ]
    }
}
