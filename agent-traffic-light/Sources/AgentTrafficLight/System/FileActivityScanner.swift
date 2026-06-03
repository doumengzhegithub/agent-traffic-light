import Foundation

struct FileActivity: Equatable, Sendable {
    let path: String
    let exists: Bool
    let modifiedAt: Date?
}

struct FileActivityScanner {
    func activity(for paths: [String]) -> [FileActivity] {
        paths.map(activity)
    }

    func activity(for path: String) -> FileActivity {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return FileActivity(path: path, exists: false, modifiedAt: nil)
        }

        let attributes = try? fileManager.attributesOfItem(atPath: path)
        return FileActivity(
            path: path,
            exists: true,
            modifiedAt: attributes?[.modificationDate] as? Date
        )
    }
}
