import FileSystem
import Foundation
import Path

enum RosalindError: LocalizedError {
    case notFound(AbsolutePath)

    var errorDescription: String? {
        switch self {
        case let .notFound(path):
            return "File not found at path \(path.pathString)"
        }
    }
}

public protocol Rosalindable {
    func analyze(path: AbsolutePath) async throws -> Report
}

public struct Rosalind: Rosalindable {
    let fileSystem: FileSysteming

    public init() {
        self.init(fileSystem: FileSystem())
    }

    init(fileSystem: FileSysteming) {
        self.fileSystem = fileSystem
    }

    public func analyze(path: AbsolutePath) async throws -> Report {
        if !(try await fileSystem.exists(path)) { throw RosalindError.notFound(path) }
        return try await traverse(path: path, normalizingPath: path)
    }

    public func traverse(path: AbsolutePath, normalizingPath: AbsolutePath) async throws -> Report {
        let children: [Report] = try await (try await fileSystem.glob(directory: path, include: ["*"]).collect()).sorted()
            .asyncMap { try await traverse(path: $0, normalizingPath: normalizingPath) }
        if path.extension == "app" {
            return .app(path: path.relative(to: normalizingPath).pathString, children: children)
        } else {
            return .unknown(path: path.relative(to: normalizingPath).pathString, children: children)
        }
    }
}
