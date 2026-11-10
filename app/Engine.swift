import Foundation

struct EngineFailure: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}

/// The door to the Form engine: one line in, one JSON line out, run by the kernel's `fkwu`.
struct Engine {
    /// This repo: holds `engine/` and `data/`.
    var root: URL
    /// A coherence-kernel checkout: holds `fkwu`, `form/` and `runtime/`.
    var kernel: URL

    static let defaultRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().path
    static let defaultKernel = URL(fileURLWithPath: defaultRoot).deletingLastPathComponent().appendingPathComponent("coherence-kernel").path

    private var fkwu: URL { kernel.appendingPathComponent("fkwu") }

    /// The kernel compiles BML against its own `form/` and `runtime/` trees, read from the working
    /// directory; they stand in this repo as links to the kernel checkout.
    private func prepare() throws {
        let files = FileManager.default
        guard files.isExecutableFile(atPath: fkwu.path) else {
            throw EngineFailure(message: "No fkwu at \(fkwu.path). Set the coherence-kernel folder in Settings.")
        }
        guard files.fileExists(atPath: root.appendingPathComponent("engine/chart-run.bml").path) else {
            throw EngineFailure(message: "No engine at \(root.path). Set the form-jyotish folder in Settings.")
        }
        guard files.fileExists(atPath: root.appendingPathComponent("data/de440s.bsp").path) else {
            throw EngineFailure(message: "The ephemeris data/de440s.bsp is absent. The README says where it comes from.")
        }
        for name in ["form", "runtime"] {
            let link = root.appendingPathComponent(name)
            if !files.fileExists(atPath: link.path) {
                try? files.removeItem(at: link)
                try files.createSymbolicLink(at: link, withDestinationURL: kernel.appendingPathComponent(name))
            }
        }
    }

    func chart(for birth: Birth, node: String, ayanamsa: String) throws -> Chart {
        guard let jd = birth.julianDay, let zone = birth.zoneHours else {
            throw EngineFailure(message: "The date reads as YYYY-MM-DD, the time as HH:MM:SS, and the zone as a name like Asia/Kolkata.")
        }
        return try chart(julianDay: jd, latitude: birth.latitude, longitude: birth.longitude, node: node, ayanamsa: ayanamsa, zoneHours: zone)
    }

    func chart(julianDay: Double, latitude: Double, longitude: Double, node: String, ayanamsa: String, zoneHours: Double) throws -> Chart {
        try prepare()
        let errors = FileManager.default.temporaryDirectory.appendingPathComponent("form-jyotish-\(UUID().uuidString).err")
        FileManager.default.createFile(atPath: errors.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: errors) }

        let process = Process()
        process.executableURL = fkwu
        process.arguments = ["engine/chart-run.bml"]
        process.currentDirectoryURL = root
        let input = Pipe(), output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = try FileHandle(forWritingTo: errors)
        try process.run()
        let line = String(format: "%.9f %.6f %.6f %@ %@ %.4f\n", julianDay, latitude, longitude, node, ayanamsa, zoneHours)
        input.fileHandleForWriting.write(Data(line.utf8))
        try input.fileHandleForWriting.close()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let text = String(decoding: data, as: UTF8.self)
        guard let json = text.split(separator: "\n").first(where: { $0.hasPrefix("{") }) else {
            let said = (try? String(contentsOf: errors, encoding: .utf8))?.split(separator: "\n").first.map(String.init) ?? "no output"
            throw EngineFailure(message: "The engine returned no chart (exit \(process.terminationStatus)): \(said)")
        }
        let bytes = Data(json.utf8)
        if let refusal = try? JSONDecoder().decode([String: String].self, from: bytes), let why = refusal["error"] {
            throw EngineFailure(message: why)
        }
        return try JSONDecoder().decode(Chart.self, from: bytes)
    }
}
