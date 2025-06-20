/**
*  Publish
*  Copyright (c) John Sundell 2020
*  MIT license, see LICENSE file for details
*/

import Testing
import Publish
import Synchronization

@Suite("PublishingContext", .serialized) struct PublishingContextTests: PublishTestCase {
    @Test func testSectionIterationOrder() throws {
        let expectedOrder = WithoutItemMetadata.SectionID.allCases
        let actualOrder = Mutex([WithoutItemMetadata.SectionID]())

        try publishWebsite(using: [
            .step(named: "Step") { context in
                context.sections.forEach { section in
                    actualOrder.withLock { $0.append(section.id) }
                }
            }
        ])

        let order = actualOrder.withLock( \.self )
        #expect(expectedOrder == order)
    }
}
