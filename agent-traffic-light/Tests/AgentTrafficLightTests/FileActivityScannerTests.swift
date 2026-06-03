import Foundation
import Testing
@testable import AgentTrafficLight

struct FileActivityScannerTests {
    @Test
    func testActivityForExistingFileReturnsModificationDate() throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: directory)
        }

        let file = directory.appendingPathComponent("codex.log")
        try "log".write(to: file, atomically: true, encoding: .utf8)

        let scanner = FileActivityScanner()
        let activity = scanner.activity(for: file.path)

        #expect(activity.path == file.path)
        #expect(activity.exists)
        #expect(activity.modifiedAt != nil)
    }

    @Test
    func testActivityForMissingFileReturnsMissingState() {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .path

        let scanner = FileActivityScanner()
        let activity = scanner.activity(for: path)

        #expect(activity == FileActivity(path: path, exists: false, modifiedAt: nil))
    }

    @Test
    func testActivityForMultiplePathsPreservesInputOrder() throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? fileManager.removeItem(at: directory)
        }

        let existing = directory.appendingPathComponent("existing")
        let missing = directory.appendingPathComponent("missing")
        try "x".write(to: existing, atomically: true, encoding: .utf8)

        let scanner = FileActivityScanner()
        let activities = scanner.activity(for: [missing.path, existing.path])

        #expect(activities.map(\.path) == [missing.path, existing.path])
        #expect(activities.map(\.exists) == [false, true])
    }
}
