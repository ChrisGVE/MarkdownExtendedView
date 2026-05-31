// MermaidTests.swift
// MarkdownExtendedView
//
// Copyright 2025 Christian C. Berclaz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import XCTest
import Markdown
@testable import MarkdownExtendedView

final class MermaidTests: XCTestCase {

    // MARK: - Parser Detection Tests

    func testParserDetectsMermaidCodeBlock() {
        let markdown = """
        ```mermaid
        graph TD
            A --> B
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "mermaid")
    }

    func testParserDetectsFlowchartDiagram() {
        let markdown = """
        ```mermaid
        flowchart LR
            A[Start] --> B{Decision}
            B -->|Yes| C[OK]
            B -->|No| D[Cancel]
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "mermaid")
        XCTAssertTrue(codeBlock.code.contains("flowchart"))
    }

    func testParserDetectsSequenceDiagram() {
        let markdown = """
        ```mermaid
        sequenceDiagram
            Alice->>John: Hello John
            John-->>Alice: Hi Alice
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "mermaid")
        XCTAssertTrue(codeBlock.code.contains("sequenceDiagram"))
    }

    func testParserDetectsClassDiagram() {
        let markdown = """
        ```mermaid
        classDiagram
            Animal <|-- Dog
            Animal : +int age
            Dog : +bark()
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "mermaid")
        XCTAssertTrue(codeBlock.code.contains("classDiagram"))
    }

    // MARK: - Feature Flag Tests

    func testMermaidFlagDisabledByDefault() {
        let features = MarkdownFeatures.none
        XCTAssertFalse(features.contains(.mermaid))
    }

    func testMermaidCanBeEnabled() {
        let features: MarkdownFeatures = .mermaid
        XCTAssertTrue(features.contains(.mermaid))
    }

    func testMermaidInAllFeatures() {
        let features = MarkdownFeatures.all
        XCTAssertTrue(features.contains(.mermaid))
    }

    // MARK: - Helper Function Tests

    func testIsMermaidCodeBlock() {
        let mermaidMarkdown = """
        ```mermaid
        graph TD
            A --> B
        ```
        """
        let mermaidDoc = Document(parsing: mermaidMarkdown)
        guard let mermaidBlock = mermaidDoc.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse mermaid block")
            return
        }
        XCTAssertEqual(mermaidBlock.language, "mermaid")

        let swiftMarkdown = """
        ```swift
        let x = 5
        ```
        """
        let swiftDoc = Document(parsing: swiftMarkdown)
        guard let swiftBlock = swiftDoc.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse swift block")
            return
        }
        XCTAssertEqual(swiftBlock.language, "swift")
        XCTAssertNotEqual(swiftBlock.language, "mermaid")
    }

    // MARK: - Multiple Diagrams Tests

    func testMultipleMermaidDiagrams() {
        let markdown = """
        # First Diagram

        ```mermaid
        graph TD
            A --> B
        ```

        # Second Diagram

        ```mermaid
        sequenceDiagram
            A->>B: Message
        ```
        """
        let document = Document(parsing: markdown)

        var mermaidCount = 0
        for child in document.children {
            if let codeBlock = child as? CodeBlock,
               codeBlock.language == "mermaid" {
                mermaidCount += 1
            }
        }

        XCTAssertEqual(mermaidCount, 2)
    }

    // MARK: - Complex Diagram Tests

    func testPieDiagram() {
        let markdown = """
        ```mermaid
        pie title Pets adopted by families
            "Dogs" : 386
            "Cats" : 85
            "Rats" : 15
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "mermaid")
        XCTAssertTrue(codeBlock.code.contains("pie"))
    }

    func testGanttDiagram() {
        let markdown = """
        ```mermaid
        gantt
            title A Gantt Diagram
            dateFormat YYYY-MM-DD
            section Section
            A task :a1, 2024-01-01, 30d
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "mermaid")
        XCTAssertTrue(codeBlock.code.contains("gantt"))
    }

    func testStateDiagram() {
        let markdown = """
        ```mermaid
        stateDiagram-v2
            [*] --> Still
            Still --> [*]
            Still --> Moving
            Moving --> Still
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "mermaid")
        XCTAssertTrue(codeBlock.code.contains("stateDiagram"))
    }

    // MARK: - Security Tests

    func testGeneratedHTMLEscapesScriptInjection() {
        let malicious = "graph TD; A-->B<script>alert(1)</script>"
        let html = generateHTML(for: malicious)

        // The injected script must not survive as live markup.
        XCTAssertFalse(
            html.contains("<script>alert(1)</script>"),
            "raw <script> from diagram source must be HTML-escaped"
        )
        // It must appear in escaped form inside the diagram container.
        XCTAssertTrue(
            html.contains("&lt;script&gt;alert(1)&lt;/script&gt;"),
            "diagram source should be HTML-escaped, got: \(html)"
        )
    }

    func testGeneratedHTMLEscapesAngleBracketsAndAmpersands() {
        let html = generateHTML(for: "A & B < C > D")
        XCTAssertTrue(html.contains("A &amp; B &lt; C &gt; D"))
    }

    func testGeneratedHTMLUsesStrictSecurityLevel() {
        let html = generateHTML(for: "graph TD; A-->B")
        XCTAssertTrue(html.contains("securityLevel: 'strict'"), "must use strict security level")
        XCTAssertFalse(html.contains("securityLevel: 'loose'"), "loose security level is unsafe")
    }

    func testGeneratedHTMLDisablesHTMLLabels() {
        let html = generateHTML(for: "graph TD; A-->B")
        XCTAssertTrue(html.contains("htmlLabels: false"), "HTML labels must be disabled under strict mode")
    }

    func testAmpersandEscapedBeforeOtherEntities() {
        // Ensure no double-escaping: "&lt;" in source becomes "&amp;lt;", not "&lt;".
        let html = generateHTML(for: "&lt;")
        XCTAssertTrue(html.contains("&amp;lt;"))
    }

    // MARK: - Supply-Chain Hardening Tests (task 6)

    func testMermaidScriptIsPinnedToExactVersion() {
        let html = generateHTML(for: "graph TD; A-->B")
        XCTAssertTrue(html.contains("mermaid@\(MermaidAsset.version)/dist/mermaid.min.js"),
                      "Mermaid script must be pinned to an exact, immutable version")
        XCTAssertFalse(html.contains("npm/mermaid/dist"),
                       "must not load the mutable unpinned asset path")
    }

    func testMermaidVersionIsFullyQualified() {
        // A fully-qualified version is immutable on jsDelivr; ranges like "11" are not.
        let components = MermaidAsset.version.split(separator: ".")
        XCTAssertEqual(components.count, 3, "version must be MAJOR.MINOR.PATCH")
        XCTAssertTrue(components.allSatisfy { Int($0) != nil }, "version components must be numeric")
    }

    func testMermaidScriptHasSubresourceIntegrity() {
        let html = generateHTML(for: "graph TD; A-->B")
        XCTAssertTrue(html.contains("integrity=\"\(MermaidAsset.integrity)\""),
                      "pinned script must carry an SRI hash")
        XCTAssertTrue(MermaidAsset.integrity.hasPrefix("sha384-"), "SRI hash should be sha384")
        XCTAssertTrue(html.contains("crossorigin=\"anonymous\""),
                      "SRI requires crossorigin on the script element")
    }

    func testGeneratedHTMLHasRestrictiveCSP() {
        let html = generateHTML(for: "graph TD; A-->B")
        XCTAssertTrue(html.contains("Content-Security-Policy"), "must declare a CSP")
        XCTAssertTrue(html.contains("default-src 'none'"),
                      "CSP must deny by default and only allow what is needed")
        XCTAssertTrue(html.contains("script-src 'unsafe-inline' https://cdn.jsdelivr.net"),
                      "CSP must restrict scripts to inline init plus the pinned CDN host")
    }

    func testGeneratedHTMLSignalsRenderState() {
        // The page must signal success/failure so the native layer can show a
        // retry fallback (task 7).
        let html = generateHTML(for: "graph TD; A-->B")
        XCTAssertTrue(html.contains("data-mermaid"), "render state must be exposed for failure detection")
        XCTAssertTrue(html.contains("mermaid.run("), "explicit run is needed to observe completion")
    }
}
