/**
*  Ink
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import XCTest
import Publish

final class CodeTests: XCTestCase {
    func testInlineCode() {
        let html = MarkdownParser().html(from: "Hello `inline.code()`")
        XCTAssertEqual(html, "<p>Hello <code>inline.code()</code></p>")
    }

    func testCodeBlockWithJustBackticks() {
        let html = MarkdownParser().html(from: """
        ```
        code()
        block()
        ```
        """)

        XCTAssertEqual(html, "<pre><code>code()\nblock()\n</code></pre>")
    }

    func testCodeBlockWithBackticksAndLabel() {
        let html = MarkdownParser().html(from: """
        ```swift
        code()
        ```
        """)

        XCTAssertEqual(html, "<pre><code class=\"language-swift\">code()\n</code></pre>")
    }
    
    func testCodeBlockWithBackticksAndLabelNeedingTrimming() {
       // there are 2 spaces after the swift label that need trimming too
       let html = MarkdownParser().html(from: """
       ``` swift  
       code()
       ```
       """)

       XCTAssertEqual(html, "<pre><code class=\"language-swift\">code()\n</code></pre>")
   }
    
    func testCodeBlockManyBackticks() {
        // there are 2 spaces after the swift label that need trimming too
        let html = MarkdownParser().html(from: """
        
        ```````````````````````````````` foo
        bar
        ````````````````````````````````
        """)

        XCTAssertEqual(html, "<pre><code class=\"language-foo\">bar\n</code></pre>")
    }
    
    func testEncodingSpecialCharactersWithinCodeBlock() {
        let html = MarkdownParser().html(from: """
        ```swift
        Generic<T>() && expression()
        ```
        """)

        XCTAssertEqual(html, """
        <pre><code class="language-swift">Generic&lt;T&gt;() &amp;&amp; expression()\n</code></pre>
        """)
    }

    func testIgnoringFormattingWithinCodeBlock() {
        let html = MarkdownParser().html(from: """
        ```
        # Not A Header
        return View()
        - Not a list
        ```
        """)

        XCTAssertEqual(html, """
        <pre><code># Not A Header
        return View()
        - Not a list\n</code></pre>
        """)
    }
}
