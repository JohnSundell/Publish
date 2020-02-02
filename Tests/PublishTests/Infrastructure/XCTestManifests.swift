/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest

public func allTests() -> [Linux.TestCase] {
    return [
        Linux.makeTestCase(using: CLITests.allTests),
        Linux.makeTestCase(using: ContentMutationTests.allTests),
        Linux.makeTestCase(using: DeploymentTests.allTests),
        Linux.makeTestCase(using: ErrorTests.allTests),
        Linux.makeTestCase(using: FileIOTests.allTests),
        Linux.makeTestCase(using: HTMLGenerationTests.allTests),
        Linux.makeTestCase(using: MarkdownTests.allTests),
        Linux.makeTestCase(using: PathTests.allTests),
        Linux.makeTestCase(using: PlotComponentTests.allTests),
        Linux.makeTestCase(using: PluginTests.allTests),
        Linux.makeTestCase(using: PodcastFeedGenerationTests.allTests),
        Linux.makeTestCase(using: PublishingContextTests.allTests),
        Linux.makeTestCase(using: RSSFeedGenerationTests.allTests),
        Linux.makeTestCase(using: SiteMapGenerationTests.allTests),
        Linux.makeTestCase(using: WebsiteTests.allTests)
    ]
}
