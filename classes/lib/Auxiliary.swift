

import Foundation

#if !arch(x86_64) && !arch(i386)

	func debugPrint(items: Any ..., separator: String = " ", terminator: String = "\n") { }
	func print(items: Any ..., separator: String = " ", terminator: String = "\n") { }

#endif

func LOG(object: Any = "", method: String = #function) {
	print("\(method) | \(object)")
}


public struct Dispatch {

	public static func main(block: dispatch_block_t) {
		return dispatch_async(dispatch_get_main_queue(), block)
	}

	public static func background(block: dispatch_block_t) {
		return dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block)
	}

}

public struct Path {
	public static var documents: String { return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] }
	public static var caches: String { return NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] }
	public static var library: String { return NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0] }
	public static var support: String { return NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0] }
	public static var temp: String { return NSTemporaryDirectory() }
	public static var resource: String { return NSBundle.mainBundle().resourcePath ?? "" }

	public static func documtnts(path: String) -> String { return Path.documents.appendPath(path) }
	public static func caches(path: String) -> String { return Path.caches.appendPath(path) }
	public static func library(path: String) -> String { return Path.library.appendPath(path) }
	public static func support(path: String) -> String { return Path.support.appendPath(path) }
	public static func resource(path: String) -> String { return Path.resource.appendPath(path) }

	public static func remove(path: String) -> Bool {
		do {
			try NSFileManager.defaultManager().removeItemAtPath(path)
		} catch { return false }
		return true
	}

	public static func move(src: String, dst: String) -> Bool {
		do {
			try NSFileManager.defaultManager().moveItemAtPath(src, toPath: dst)
		} catch { return false }
		return true
	}

	public static func copy(src: String, dst: String) -> Bool {
		do {
			try NSFileManager.defaultManager().copyItemAtPath(src, toPath: dst)
		} catch { return false }
		return true
	}

	public static func mkdir(path: String) -> Bool {
		do {
			try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
		} catch { return false }
		return true
	}

	public static func files(path: String) -> [String] {
		return (try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)) ?? []
	}

	public static func exists(path: String) -> Bool {
		return NSFileManager.defaultManager().fileExistsAtPath(path)
	}

	public static func isFile(path: String) -> Bool {
		var isdir: ObjCBool = false
		let exist = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isdir)
		return exist && !isdir
	}

	public static func isDir(path: String) -> Bool {
		var isdir: ObjCBool = false
		let exist = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isdir)
		return exist && isdir
	}

	public static func attributes(path: String) -> [String: AnyObject] {
		return (try? NSFileManager.defaultManager().attributesOfItemAtPath(path)) ?? [:]
	}
}

