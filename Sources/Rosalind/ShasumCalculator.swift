import Command
import Crypto
@preconcurrency import FileSystem
import Foundation
import Path

protocol ShasumCalculating: Sendable {
    func calculate(childrenShasums: [String]) async throws -> String
    func calculate(filePath: AbsolutePath) async throws -> String
}

struct ShasumCalculator: ShasumCalculating {
    private let fileSystem: FileSysteming
    private let commandRunner: CommandRunning

    init(fileSystem: FileSysteming = FileSystem(), commandRunner: CommandRunning = CommandRunner()) {
        self.fileSystem = fileSystem
        self.commandRunner = commandRunner
    }

    func calculate(childrenShasums: [String]) async throws -> String {
        let digest = SHA256.hash(data: childrenShasums.joined().data(using: .utf8)!)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    func calculate(filePath: Path.AbsolutePath) async throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filePath.pathString))
        defer { try? fileHandle.close() }

        var hasher = SHA256()

        let chunkSize = 1024 * 1024

        while autoreleasepool(invoking: {
            guard let data = try? fileHandle.read(upToCount: chunkSize), !data.isEmpty else {
                return false
            }
            hasher.update(data: data)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
