//
//  mdxplayerUITests.swift
//  mdxplayerUITests
//

import XCTest

class mdxplayerUITests: XCTestCase {

	override func setUp() {
		super.setUp()

		let app = XCUIApplication()
		setupSnapshot(app)
		app.launch()

		sleep(3)
		snapshot("aaa")

		app.tables.staticTexts["Build-in"].tap()
        sleep(1)
		app.tables.cells.staticTexts["X68030のテーマ (w/o Vo.) / moyashi (@hitoriblog)"].tap()
		app.buttons["arrow up"].tap()
		sleep(3)
		snapshot("bbb")

		sleep(1)

	}

	override func tearDown() {
		super.tearDown()
	}

	func testExample() { }
}

