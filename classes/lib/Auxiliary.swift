

import Foundation

#if !arch(x86_64) && !arch(i386)

    func debugPrint(items _: Any ..., separator _: String = " ", terminator _: String = "\n") {}
    func print(items _: Any ..., separator _: String = " ", terminator _: String = "\n") {}

#endif

func LOG(_ object: Any = "", method: String = #function) {
    print("\(method) | \(object)")
}

public struct Dispatch {
    public static func main(_ block: @escaping () -> Void) {
        return DispatchQueue.main.async(execute: block)
    }

    public static func background(_ block: @escaping () -> Void) {
        return DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: block)
    }
}

public struct Path {
    public static var documents: String { return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] }
    public static var caches: String { return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] }
    public static var library: String { return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] }
    public static var support: String { return NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0] }
    public static var temp: String { return NSTemporaryDirectory() }
    public static var resource: String { return Bundle.main.resourcePath ?? "" }

    public static func documtnts(_ path: String) -> String { return Path.documents.appendPath(path) }
    public static func caches(_ path: String) -> String { return Path.caches.appendPath(path) }
    public static func library(_ path: String) -> String { return Path.library.appendPath(path) }
    public static func support(_ path: String) -> String { return Path.support.appendPath(path) }
    public static func resource(_ path: String) -> String { return Path.resource.appendPath(path) }

    @discardableResult public static func remove(_ path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch { return false }
        return true
    }

    @discardableResult public static func move(_ src: String, dst: String) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: src, toPath: dst)
        } catch { return false }
        return true
    }

    @discardableResult public static func copy(_ src: String, dst: String) -> Bool {
        do {
            try FileManager.default.copyItem(atPath: src, toPath: dst)
        } catch { return false }
        return true
    }

    @discardableResult public static func mkdir(_ path: String) -> Bool {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch { return false }
        return true
    }

    public static func files(_ path: String) -> [String] {
        return (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
    }

    public static func exists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    public static func isFile(_ path: String) -> Bool {
        var isdir: ObjCBool = false
        let exist = FileManager.default.fileExists(atPath: path, isDirectory: &isdir)
        return exist && !isdir.boolValue
    }

    public static func isDir(_ path: String) -> Bool {
        var isdir: ObjCBool = false
        let exist = FileManager.default.fileExists(atPath: path, isDirectory: &isdir)
        return exist && isdir.boolValue
    }

    public static func attributes(_ path: String) -> [FileAttributeKey: Any] {
        return (try? FileManager.default.attributesOfItem(atPath: path)) ?? [:]
    }
}
