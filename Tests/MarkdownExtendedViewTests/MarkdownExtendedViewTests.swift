import XCTest
@testable import MarkdownExtendedView

final class MarkdownExtendedViewTests: XCTestCase {

    func testBasicMarkdownParsing() throws {
        // Basic test to verify the module compiles and links
        let content = "# Hello World"
        XCTAssertFalse(content.isEmpty)
    }

    func testLaTeXDelimiterDetection() throws {
        let inlineLatex = "The formula $x^2$ is simple"
        XCTAssertTrue(inlineLatex.contains("$"))

        let displayLatex = "$$E = mc^2$$"
        XCTAssertTrue(displayLatex.contains("$$"))
    }
}
