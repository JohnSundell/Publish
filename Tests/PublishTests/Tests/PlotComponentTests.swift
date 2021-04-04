/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Plot

final class PlotComponentTests: PublishTestCase {
    func testStylesheetPaths() {
        let html = Node.head(
            for: Page(path: "path", content: Content()),
            on: WebsiteStub.WithoutItemMetadata(),
            stylesheetPaths: [
                "local-1.css",
                "/local-2.css",
                "http://external-1.css",
                "https://external-2.css"
            ]
        ).render()

        let expectedURLs = [
            "/local-1.css",
            "/local-2.css",
            "http://external-1.css",
            "https://external-2.css"
        ]

        for url in expectedURLs {
            XCTAssertTrue(html.contains("""
            <link rel="stylesheet" href="\(url)" type="text/css"/>
            """))
        }
    }

    func testTitleStyleDefault() {
        let html = Node.head(
            for: Page(path: "path", content: Content(title: "A Title")),
            on: WebsiteStub.WithoutItemMetadata()
        ).render()

        XCTAssertTrue(html.contains(#"<title>A Title | WebsiteName</title>"#))
    }

    func testTitleStyleLocationTitle() {
        let html = Node.head(
            for: Page(path: "path", content: Content(title: "A Title")),
            on: WebsiteStub.WithoutItemMetadata(),
            titleStyle: .locationTitle
        ).render()

        XCTAssertTrue(html.contains(#"<title>A Title</title>"#))
    }

    func testTitleStyleFixed() {
        let html = Node.head(
            for: Page(path: "path", content: Content(title: "A Title")),
            on: WebsiteStub.WithoutItemMetadata(),
            titleStyle: .fixed(string: "Custom")
        ).render()

        XCTAssertTrue(html.contains(#"<title>Custom</title>"#))
    }

    func testTitleStyleSeparator() {
        let html = Node.head(
            for: Page(path: "path", content: Content(title: "A Title")),
            on: WebsiteStub.WithoutItemMetadata(),
            titleStyle: .titleAndSiteName(separator: " • ")
        ).render()

        XCTAssertTrue(html.contains(#"<title>A Title • WebsiteName</title>"#))
    }

    func testRenderingAudioPlayer() throws {
        let url = try require(URL(string: "https://audio.mp3"))
        let audio = Audio(url: url, format: .mp3)
        let html = Node.audioPlayer(for: audio).render()

        XCTAssertEqual(html, """
        <audio controls><source type="audio/mpeg" src="https://audio.mp3"/></audio>
        """)
    }

    func testRenderingHostedVideoPlayer() throws {
        let url = try require(URL(string: "https://video.mp4"))
        let video = Video.hosted(url: url, format: .mp4)
        let html = Node.videoPlayer(for: video).render()

        XCTAssertEqual(html, """
        <video controls><source type="video/mp4" src="https://video.mp4"/></video>
        """)
    }

    func testRenderingYouTubeVideoPlayer() {
        let video = Video.youTube(id: "123")
        let html = Node.videoPlayer(for: video).render()

        XCTAssertEqual(html, """
        <iframe frameborder="0"\
         allow="accelerometer; encrypted-media; gyroscope; picture-in-picture"\
         allowfullscreen="true"\
         src="https://www.youtube-nocookie.com/embed/123"\
        ></iframe>
        """)
    }

    func testRenderingVimeoVideoPlayer() {
        let video = Video.vimeo(id: "123")
        let html = Node.videoPlayer(for: video).render()

        XCTAssertEqual(html, """
        <iframe frameborder="0"\
         allow="accelerometer; encrypted-media; gyroscope; picture-in-picture"\
         allowfullscreen="true"\
         src="https://player.vimeo.com/video/123"\
        ></iframe>
        """)
    }
}

extension PlotComponentTests {
    static var allTests: Linux.TestList<PlotComponentTests> {
        [
            ("testStylesheetPaths", testStylesheetPaths),
            ("testTitleStyleDefault", testTitleStyleDefault),
            ("testTitleStyleLocationTitle", testTitleStyleLocationTitle),
            ("testTitleStyleFixed", testTitleStyleFixed),
            ("testTitleStyleSeparator", testTitleStyleSeparator),
            ("testRenderingAudioPlayer", testRenderingAudioPlayer),
            ("testRenderingHostedVideoPlayer", testRenderingHostedVideoPlayer),
            ("testRenderingYouTubeVideoPlayer", testRenderingYouTubeVideoPlayer),
            ("testRenderingVimeoVideoPlayer", testRenderingVimeoVideoPlayer)
        ]
    }
}
