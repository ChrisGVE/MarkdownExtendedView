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
}
