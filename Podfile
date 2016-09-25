platform :ios, '8.0'
use_frameworks!

target "mdxplayer" do
    pod 'SwiftyDropbox'
end


ts: XCTestCase {

	override func setUp() {
		super.setUp()

		let app = XCUIApplication()
		setupSnapshot(app)
		app.launch()

		sleep(3)
		snapshot("aaa")

		app.tables.staticTexts["Build-in"].tap()
        sleep(1)