// archiver.swift
import Foundation

let cloudDir = "cloud"

func ensureCloudDir() throws {
    try FileManager.default.createDirectory(atPath: cloudDir, withIntermediateDirectories: true, attributes: nil)
}

func archiveName() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    return "archive_\(formatter.string(from: Date())).zip"
}

func addFiles(paths: [String]) {
    do {
        try ensureCloudDir()
        let name = archiveName()
        let archivePath = URL(fileURLWithPath: cloudDir).appendingPathComponent(name)
        // Create a temporary directory to store files to zip
        // Use Process to invoke zip command? Or use a library. 
        // For simplicity, we'll use the built-in `zip` command (available on macOS/Linux).
        // This is not cross-platform (Windows doesn't have zip command).
        // We'll use a combination of `zip` command.
        // For a pure Swift solution, we could use a third-party library.
        // I'll use the `zip` command.
        var args = ["zip", "-r", archivePath.path]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                args.append(path)
            } else {
                print("Warning: \(path) does not exist, skipping.")
            }
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = args
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("Archive created: \(archivePath.path)")
        } else {
            print("Failed to create archive.")
        }
    } catch {
        print("Error: \(error)")
    }
}

func listArchives() {
    do {
        try ensureCloudDir()
        let files = try FileManager.default.contentsOfDirectory(atPath: cloudDir)
        let archives = files.filter { $0.hasSuffix(".zip") }.sorted()
        if archives.isEmpty {
            print("No archives found.")
            return
        }
        print("Archives:")
        for a in archives {
            let attrs = try FileManager.default.attributesOfItem(atPath: cloudDir + "/" + a)
            let size = attrs[.size] as? Int64 ?? 0
            print("  \(a) (\(size) bytes)")
        }
    } catch {
        print("Error: \(error)")
    }
}

func extractArchive(_ archiveName: String) {
    do {
        try ensureCloudDir()
        let archivePath = cloudDir + "/" + archiveName
        guard FileManager.default.fileExists(atPath: archivePath) else {
            print("Archive '\(archiveName)' not found.")
            return
        }
        // Use unzip command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", archivePath, "-d", "."]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("Extracted '\(archiveName)' to current directory.")
        } else {
            print("Failed to extract archive.")
        }
    } catch {
        print("Error: \(error)")
    }
}

func main() {
    let args = CommandLine.arguments.dropFirst()
    if args.count < 1 {
        print("Usage: swift archiver.swift <add|list|extract> [args...]")
        return
    }
    let cmd = args[0]
    switch cmd {
    case "add":
        if args.count < 2 {
            print("Usage: archiver.swift add <file/dir> [<file/dir>...]")
            return
        }
        addFiles(paths: Array(args.dropFirst()))
    case "list":
        listArchives()
    case "extract":
        if args.count != 2 {
            print("Usage: archiver.swift extract <archive_name>")
            return
        }
        extractArchive(args[1])
    default:
        print("Unknown command: \(cmd)")
    }
}

main()
