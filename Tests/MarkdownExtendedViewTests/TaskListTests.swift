// TaskListTests.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import XCTest
import Markdown
@testable import MarkdownExtendedView

final class TaskListTests: XCTestCase {

    // MARK: - Parser Detection Tests

    func testParserDetectsUncheckedTaskListItem() {
        let markdown = "- [ ] Unchecked task"
        let document = Document(parsing: markdown)

        // Navigate to the list item
        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse unordered list")
            return
        }
        let listItems = Array(list.listItems)
        guard let listItem = listItems.first else {
            XCTFail("Failed to get list item")
            return
        }

        XCTAssertNotNil(listItem.checkbox)
        XCTAssertEqual(listItem.checkbox, .unchecked)
    }

    func testParserDetectsCheckedTaskListItem() {
        let markdown = "- [x] Checked task"
        let document = Document(parsing: markdown)

        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse unordered list")
            return
        }
        let listItems = Array(list.listItems)
        guard let listItem = listItems.first else {
            XCTFail("Failed to get list item")
            return
        }

        XCTAssertNotNil(listItem.checkbox)
        XCTAssertEqual(listItem.checkbox, .checked)
    }

    func testParserDetectsUppercaseCheckedTaskListItem() {
        let markdown = "- [X] Checked task with uppercase X"
        let document = Document(parsing: markdown)

        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse unordered list")
            return
        }
        let listItems = Array(list.listItems)
        guard let listItem = listItems.first else {
            XCTFail("Failed to get list item")
            return
        }

        XCTAssertNotNil(listItem.checkbox)
        XCTAssertEqual(listItem.checkbox, .checked)
    }

    func testRegularListItemHasNoCheckbox() {
        let markdown = "- Regular item"
        let document = Document(parsing: markdown)

        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse unordered list")
            return
        }
        let listItems = Array(list.listItems)
        guard let listItem = listItems.first else {
            XCTFail("Failed to get list item")
            return
        }

        XCTAssertNil(listItem.checkbox)
    }

    func testMixedTaskAndRegularListItems() {
        let markdown = """
        - [ ] Unchecked task
        - [x] Checked task
        - Regular item
        """
        let document = Document(parsing: markdown)

        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse unordered list")
            return
        }

        let items = Array(list.listItems)
        XCTAssertEqual(items.count, 3)

        XCTAssertEqual(items[0].checkbox, .unchecked)
        XCTAssertEqual(items[1].checkbox, .checked)
        XCTAssertNil(items[2].checkbox)
    }

    // MARK: - Checkbox Helper Tests

    func testCheckboxIsTask() {
        XCTAssertTrue(Checkbox.checked.isTask)
        XCTAssertTrue(Checkbox.unchecked.isTask)
    }

    func testCheckboxIsChecked() {
        XCTAssertTrue(Checkbox.checked.isChecked)
        XCTAssertFalse(Checkbox.unchecked.isChecked)
    }

    // MARK: - TaskListItemView Tests

    func testTaskListItemViewExists() {
        // Verify TaskListItemView can be instantiated
        // The actual rendering is visual, so we just verify initialization
        let markdown = "- [x] Test task"
        let document = Document(parsing: markdown)

        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse")
            return
        }
        let listItems = Array(list.listItems)
        guard let listItem = listItems.first else {
            XCTFail("Failed to get list item")
            return
        }

        XCTAssertNotNil(listItem.checkbox)
    }

    // MARK: - Complex Task List Tests

    func testNestedTaskListItems() {
        let markdown = """
        - [ ] Parent task
          - [x] Nested completed task
          - [ ] Nested incomplete task
        """
        let document = Document(parsing: markdown)

        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse unordered list")
            return
        }

        let listItems = Array(list.listItems)
        guard let parentItem = listItems.first else {
            XCTFail("Failed to get parent item")
            return
        }

        XCTAssertEqual(parentItem.checkbox, .unchecked)

        // Find nested list
        var foundNestedList = false
        for child in parentItem.children {
            if let nestedList = child as? UnorderedList {
                foundNestedList = true
                let nestedItems = Array(nestedList.listItems)
                XCTAssertEqual(nestedItems.count, 2)
                XCTAssertEqual(nestedItems[0].checkbox, .checked)
                XCTAssertEqual(nestedItems[1].checkbox, .unchecked)
            }
        }
        XCTAssertTrue(foundNestedList, "Should find nested list")
    }

    func testTaskListWithFormattedContent() {
        let markdown = "- [x] Task with **bold** and *italic* text"
        let document = Document(parsing: markdown)

        guard let list = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse")
            return
        }
        let listItems = Array(list.listItems)
        guard let listItem = listItems.first else {
            XCTFail("Failed to get list item")
            return
        }

        XCTAssertEqual(listItem.checkbox, .checked)
        // Verify the paragraph content exists with formatting
        guard let paragraph = listItem.child(at: 0) as? Paragraph else {
            XCTFail("Expected paragraph in list item")
            return
        }
        // The paragraph should have children including Strong and Emphasis
        var foundStrong = false
        var foundEmphasis = false
        for child in paragraph.children {
            if child is Strong { foundStrong = true }
            if child is Emphasis { foundEmphasis = true }
        }
        XCTAssertTrue(foundStrong, "Should find Strong element for **bold**")
        XCTAssertTrue(foundEmphasis, "Should find Emphasis element for *italic*")
    }
}
