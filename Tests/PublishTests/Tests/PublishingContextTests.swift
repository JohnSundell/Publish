/**
*  Publish
*  Copyright (c) John Sundell 2020
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class PublishingContextTests: PublishTestCase {
    func testSectionIterationOrder() throws {
        let expectedOrder = WebsiteStub.SectionID.allCases
        var actualOrder = [WebsiteStub.SectionID]()

        try publishWebsite(using: [
            .step(named: "Step") { context in
                context.sections.forEach { section in
                    actualOrder.append(section.id)
                }
            }
        ])

        XCTAssertEqual(expectedOrder, actualOrder)
    }
}

extension PublishingContextTests {
    static var allTests: Linux.TestList<PublishingContextTests> {
        [
            ("testSectionIterationOrder", testSectionIterationOrder)
        ]
    }
}
