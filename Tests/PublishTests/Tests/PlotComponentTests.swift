/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish
import Plot

final class PlotComponentTests: PublishTestCase {
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
            ("testRenderingAudioPlayer", testRenderingAudioPlayer),
            ("testRenderingHostedVideoPlayer", testRenderingHostedVideoPlayer),
            ("testRenderingYouTubeVideoPlayer", testRenderingYouTubeVideoPlayer),
            ("testRenderingVimeoVideoPlayer", testRenderingVimeoVideoPlayer)
        ]
    }
}
