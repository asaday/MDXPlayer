
import UIKit

public extension NSObject {
	func removeNotifications() {
		NSObject.cancelPreviousPerformRequestsWithTarget(self)
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func addNotification(aSelector: Selector, name aName: String) {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: aSelector, name: aName, object: nil)
	}

	func postNotification(name: String, object anObject: AnyObject?) {
		NSNotificationCenter.defaultCenter().postNotificationName(name, object: anObject)
	}

}

public extension String {
	func to_ns() -> NSString { return (self as NSString) }
	var lastPathComponent: String { return to_ns().lastPathComponent }

	func appendPath(path: String) -> String {
		let result = to_ns().stringByAppendingPathComponent(path)

		if !self.hasString("://") { return result }
		guard let c = NSURLComponents(string: self) else { return result }

		if c.path == nil { c.path = "/" }
		c.path = c.path?.to_ns().stringByAppendingPathComponent(path)
		return c.string ?? result
	}

	func hasString(str: String) -> Bool {
		if let _ = rangeOfString(str) { return true }
		return false
	}

	func trim(chars: String? = nil) -> String {
		var cs = NSCharacterSet.whitespaceAndNewlineCharacterSet()
		if let c = chars { cs = NSCharacterSet(charactersInString: c) }
		return to_ns().stringByTrimmingCharactersInSet(cs)
	}

	func replace(search: String, _ replace: String) -> String {
		return to_ns().stringByReplacingOccurrencesOfString(search, withString: replace)
	}

}

