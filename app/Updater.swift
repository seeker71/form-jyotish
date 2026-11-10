import AppKit
import CryptoKit
import Foundation

/// Keeps a built app current from its GitHub releases.
///
/// A release is tagged `build-N` and carries `FormJyotish.zip` with its SHA-256 beside it. At launch a newer
/// build already fetched is put in the app's place and the app starts again as that build. While running,
/// the app asks GitHub for the latest release, and when it is newer fetches it, checks the digest, the bundle
/// identifier and the build number, and holds it ready for the next start.
@MainActor
final class Updater: ObservableObject {
    enum State: Equatable {
        case idle
        /// asked for by hand: looking
        case checking
        /// asked for by hand: this build is the latest
        case current(Int)
        case fetching(Int)
        /// fetched and checked: installs at the next start
        case ready(Int)
        case failed(String)
    }

    @Published var state: State = .idle

    static let repository = "seeker71/form-jyotish"
    static let archive = "FormJyotish.zip"

    /// this app's build number; nil when run from source, where nothing is updated
    static let build: Int? = Bundle.main.bundleURL.pathExtension == "app" ? (Bundle.main.infoDictionary?["CFBundleVersion"] as? String).flatMap(Int.init) : nil

    private static var folder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FormJyotish/update")
    }
    private static var staged: URL { folder.appendingPathComponent("FormJyotish.app") }

    private static func build(of app: URL) -> Int? {
        guard let info = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist")),
              info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier else { return nil }
        return (info["CFBundleVersion"] as? String).flatMap(Int.init)
    }

    /// At launch: when a newer build is held ready, put it where this app is and start it. Returns only when
    /// there was nothing to install or the app's place could not be written (an app run straight from a
    /// download is opened from a read-only copy; moving it to Applications ends that).
    static func installStagedAndRelaunch() {
        guard let current = build, let waiting = build(of: staged), waiting > current else { return }
        let place = Bundle.main.bundleURL
        do {
            _ = try FileManager.default.replaceItemAt(place, withItemAt: staged)
        } catch {
            return
        }
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-n", place.path]
        try? open.run()
        exit(0)
    }

    func restartNow() {
        Updater.installStagedAndRelaunch()
        state = .failed("The update could not be put in place. Move Form Jyotish to the Applications folder and start it again.")
    }

    /// Ask GitHub for the latest release and fetch it when it is newer than this build.
    /// `byHand` is the Check for updates button: it says what it found even when that is nothing new.
    func check(byHand: Bool = false) {
        guard let current = Updater.build else {
            if byHand { state = .failed("This copy runs from source and does not update itself.") }
            return
        }
        if byHand { state = .checking }
        if let waiting = Updater.build(of: Updater.staged), waiting > current { state = .ready(waiting) }
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(Updater.repository)/releases/latest")!)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                let (data, _) = try await URLSession.shared.data(for: request)
                let release = try JSONDecoder().decode(Release.self, from: data)
                guard let latest = Int(release.tag_name.dropFirst("build-".count)), release.tag_name.hasPrefix("build-") else { return }
                if let held = Updater.build(of: Updater.staged), held > current, held >= latest { state = .ready(held); return }
                guard latest > current else { if byHand { state = .current(current) }; return }
                guard let zip = release.assets.first(where: { $0.name == Updater.archive }),
                      let digest = release.assets.first(where: { $0.name == Updater.archive + ".sha256" }) else {
                    throw Problem("Build \(latest) carries no \(Updater.archive) with its digest.")
                }
                state = .fetching(latest)
                try await fetch(zip: zip.browser_download_url, digest: digest.browser_download_url, build: latest)
                state = .ready(latest)
            } catch let problem as Problem {
                state = .failed(problem.message)
            } catch {
                // offline, or GitHub did not answer: nothing to say, the next start asks again
                if byHand, case .checking = state { state = .failed("GitHub could not be reached: \(error.localizedDescription)") }
                if case .fetching = state { state = .failed("The update could not be fetched: \(error.localizedDescription)") }
            }
        }
    }

    private struct Release: Decodable {
        struct Asset: Decodable { var name: String; var browser_download_url: URL }
        var tag_name: String
        var assets: [Asset]
    }
    private struct Problem: Error { var message: String; init(_ message: String) { self.message = message } }

    private func fetch(zip: URL, digest: URL, build: Int) async throws {
        let files = FileManager.default
        try? files.removeItem(at: Updater.folder)
        try files.createDirectory(at: Updater.folder, withIntermediateDirectories: true)
        let (expectedData, _) = try await URLSession.shared.data(from: digest)
        let expected = String(decoding: expectedData, as: UTF8.self).split(whereSeparator: { $0 == " " || $0 == "\n" }).first.map(String.init) ?? ""
        let (downloaded, _) = try await URLSession.shared.download(from: zip)
        let archive = Updater.folder.appendingPathComponent(Updater.archive)
        try files.moveItem(at: downloaded, to: archive)
        let actual = SHA256.hash(data: try Data(contentsOf: archive, options: .mappedIfSafe)).map { String(format: "%02x", $0) }.joined()
        guard actual == expected.lowercased(), !expected.isEmpty else {
            try? files.removeItem(at: Updater.folder)
            throw Problem("Build \(build) did not match its published digest and was discarded.")
        }
        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzip.arguments = ["-x", "-k", archive.path, Updater.folder.path]
        try unzip.run()
        unzip.waitUntilExit()
        try? files.removeItem(at: archive)
        guard unzip.terminationStatus == 0, Updater.build(of: Updater.staged) == build else {
            try? files.removeItem(at: Updater.folder)
            throw Problem("Build \(build) could not be unpacked as Form Jyotish and was discarded.")
        }
    }
}
