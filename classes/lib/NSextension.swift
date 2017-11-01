
import UIKit

public extension NSObject {
	func removeNotifications() {
		NSObject.cancelPreviousPerformRequests(withTarget: self)
		NotificationCenter.default.removeObserver(self)
	}

	func addNotification(_ aSelector: Selector, name aName: String) {
		NotificationCenter.default.addObserver(self, selector: aSelector, name: NSNotification.Name(rawValue: aName), object: nil)
	}

	func postNotification(_ name: String, object anObject: AnyObject?) {
		NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: anObject)
	}
}

public extension String {
	func to_ns() -> NSString { return (self as NSString) }
	var lastPathComponent: String { return to_ns().lastPathComponent }

	func appendPath(_ path: String) -> String {
		let result = to_ns().appendingPathComponent(path)

		if !hasString("://") { return result }
		guard var c = URLComponents(string: self) else { return result }

		// if c.path == nil { c.path = "/" }
		c.path = c.path.to_ns().appendingPathComponent(path)
		return c.string ?? result
	}

	func hasString(_ str: String) -> Bool {
		if let _ = range(of: str) { return true }
		return false
	}

	func trim(_ chars: String? = nil) -> String {
		var cs = CharacterSet.whitespacesAndNewlines
		if let c = chars { cs = CharacterSet(charactersIn: c) }
		return to_ns().trimmingCharacters(in: cs)
	}

	func replace(_ search: String, _ replace: String) -> String {
		return to_ns().replacingOccurrences(of: search, with: replace)
	}
}
