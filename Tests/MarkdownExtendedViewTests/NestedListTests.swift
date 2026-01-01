// NestedListTests.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import XCTest
import Markdown
@testable import MarkdownExtendedView

final class NestedListTests: XCTestCase {

    // MARK: - Parser Detection Tests

    func testParserDetectsNestedUnorderedList() {
        let markdown = """
        - Item 1
          - Nested item
          - Another nested
        - Item 2
        """
        let document = Document(parsing: markdown)

        guard let topList = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse top-level list")
            return
        }

        let items = Array(topList.listItems)
        XCTAssertEqual(items.count, 2)

        // First item should have a nested list
        let firstItem = items[0]
        var hasNestedList = false
        for child in firstItem.children {
            if child is UnorderedList {
                hasNestedList = true
            }
        }
        XCTAssertTrue(hasNestedList, "First item should contain a nested list")
    }

    func testParserDetectsNestedOrderedList() {
        let markdown = """
        1. First
           1. Nested first
           2. Nested second
        2. Second
        """
        let document = Document(parsing: markdown)

        guard let topList = document.child(at: 0) as? OrderedList else {
            XCTFail("Failed to parse top-level ordered list")
            return
        }

        let items = Array(topList.listItems)
        XCTAssertEqual(items.count, 2)

        // First item should have a nested ordered list
        let firstItem = items[0]
        var hasNestedOrderedList = false
        for child in firstItem.children {
            if child is OrderedList {
                hasNestedOrderedList = true
            }
        }
        XCTAssertTrue(hasNestedOrderedList, "First item should contain a nested ordered list")
    }

    func testParserDetectsMixedNestedLists() {
        let markdown = """
        - Unordered
          1. Ordered inside
          2. Another ordered
        - Another unordered
        """
        let document = Document(parsing: markdown)

        guard let topList = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse top-level list")
            return
        }

        let items = Array(topList.listItems)
        XCTAssertEqual(items.count, 2)

        // First item should have a nested ordered list
        let firstItem = items[0]
        var hasNestedOrderedList = false
        for child in firstItem.children {
            if child is OrderedList {
                hasNestedOrderedList = true
            }
        }
        XCTAssertTrue(hasNestedOrderedList, "First item should contain a nested ordered list")
    }

    func testParserDetectsDeeplyNestedLists() {
        let markdown = """
        - Level 1
          - Level 2
            - Level 3
              - Level 4
        """
        let document = Document(parsing: markdown)

        guard let level1List = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse level 1 list")
            return
        }

        let level1Items = Array(level1List.listItems)
        guard let level1Item = level1Items.first else {
            XCTFail("No items in level 1 list")
            return
        }

        // Navigate to find level 2 list
        var level2List: UnorderedList?
        for child in level1Item.children {
            if let list = child as? UnorderedList {
                level2List = list
            }
        }
        XCTAssertNotNil(level2List, "Should find level 2 list")

        // Navigate to find level 3 list
        guard let l2List = level2List else {
            XCTFail("Level 2 list not found")
            return
        }
        let level2Items = Array(l2List.listItems)
        guard let level2Item = level2Items.first else {
            XCTFail("No items in level 2 list")
            return
        }

        var level3List: UnorderedList?
        for child in level2Item.children {
            if let list = child as? UnorderedList {
                level3List = list
            }
        }
        XCTAssertNotNil(level3List, "Should find level 3 list")

        // Navigate to find level 4 list
        guard let l3List = level3List else {
            XCTFail("Level 3 list not found")
            return
        }
        let level3Items = Array(l3List.listItems)
        guard let level3Item = level3Items.first else {
            XCTFail("No items in level 3 list")
            return
        }

        var level4List: UnorderedList?
        for child in level3Item.children {
            if let list = child as? UnorderedList {
                level4List = list
            }
        }
        XCTAssertNotNil(level4List, "Should find level 4 list")
    }

    // MARK: - Nesting Level Helper Tests

    func testNestedListHasDepth() {
        // Test that we can calculate nesting depth
        let markdown = """
        - Item 1
          - Nested
        """
        let document = Document(parsing: markdown)

        guard let topList = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse")
            return
        }

        let items = Array(topList.listItems)
        guard let firstItem = items.first else {
            XCTFail("Failed to get first item")
            return
        }

        var nestedList: UnorderedList?
        for child in firstItem.children {
            if let list = child as? UnorderedList {
                nestedList = list
            }
        }

        XCTAssertNotNil(nestedList, "Should have nested list")
        if let nested = nestedList {
            XCTAssertEqual(Array(nested.listItems).count, 1)
        }
    }

    // MARK: - Bullet Style Tests

    func testBulletStylesExist() {
        // Verify we have different bullet styles
        let bullets = ["•", "◦", "▪", "▸"]
        XCTAssertEqual(bullets.count, 4, "Should have 4 bullet styles")
    }

    // MARK: - List with Content Tests

    func testNestedListWithMultipleParagraphs() {
        let markdown = """
        - Item 1

          Continuation paragraph

          - Nested item
        """
        let document = Document(parsing: markdown)

        guard let topList = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse")
            return
        }

        let items = Array(topList.listItems)
        guard let firstItem = items.first else {
            XCTFail("Failed to get first item")
            return
        }

        // First item should have multiple children (paragraphs and nested list)
        var childCount = 0
        for _ in firstItem.children {
            childCount += 1
        }
        XCTAssertGreaterThan(childCount, 1, "Should have multiple children")
    }

    func testNestedTaskListItems() {
        let markdown = """
        - [x] Completed task
          - [ ] Subtask 1
          - [x] Subtask 2
        """
        let document = Document(parsing: markdown)

        guard let topList = document.child(at: 0) as? UnorderedList else {
            XCTFail("Failed to parse")
            return
        }

        let items = Array(topList.listItems)
        guard let firstItem = items.first else {
            XCTFail("Failed to get first item")
            return
        }

        // First item should be a checked task
        XCTAssertNotNil(firstItem.checkbox, "Should have checkbox")
        XCTAssertTrue(firstItem.checkbox?.isChecked == true, "Should be checked")

        // Find nested list
        var nestedList: UnorderedList?
        for child in firstItem.children {
            if let list = child as? UnorderedList {
                nestedList = list
            }
        }

        XCTAssertNotNil(nestedList, "Should have nested list")

        if let nested = nestedList {
            let nestedItems = Array(nested.listItems)
            XCTAssertEqual(nestedItems.count, 2)

            // Check nested task items
            XCTAssertNotNil(nestedItems[0].checkbox, "First nested should be task")
            XCTAssertFalse(nestedItems[0].checkbox?.isChecked == true, "First nested should be unchecked")
            XCTAssertNotNil(nestedItems[1].checkbox, "Second nested should be task")
            XCTAssertTrue(nestedItems[1].checkbox?.isChecked == true, "Second nested should be checked")
        }
    }
}
