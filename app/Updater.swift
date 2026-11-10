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
        relaunch(place)
    }

    /// The build of the copy that stands where this app was started from. It is ahead of the running window
    /// when the app was replaced while open: by a copy dragged over it, or by a fresh build.
    static func onDisk() -> Int? { build(of: Bundle.main.bundleURL) }

    /// Open the app that stands at `place` as a new instance, and leave. The opening is asked of the system
    /// and seen through before this process goes, so nothing has to outlive it: a helper left waiting behind
    /// can be swept away with the app that started it, and then nothing reopens. The new instance is told
    /// whom it follows (`--after`) and waits for this process to be gone before it shows itself.
    /// This ending is a clean one: the new build opens where the desk stood.
    private static func relaunch(_ place: URL) -> Never {
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        open.arguments = ["-n", place.path, "--args", "--after", "\(ProcessInfo.processInfo.processIdentifier)"]
        UserDefaults.standard.set(false, forKey: "running")
        UserDefaults.standard.synchronize()
        if (try? open.run()) != nil { open.waitUntilExit() }
        exit(0)
    }

    /// A new instance opened by `relaunch` waits here, at most five seconds, for the one before it to go.
    static func waitForPredecessor(_ arguments: [String]) {
        guard let flag = arguments.firstIndex(of: "--after"), arguments.count > flag + 1, let before = Int32(arguments[flag + 1]) else { return }
        var tries = 0
        while kill(before, 0) == 0 && tries < 100 { usleep(50_000); tries += 1 }
    }

    func restartNow() {
        // a newer copy already in place needs only the restart
        if let current = Updater.build, let disk = Updater.onDisk(), disk > current { Updater.relaunch(Bundle.main.bundleURL) }
        Updater.installStagedAndRelaunch()
        state = .failed("The update could not be put in place. Move Form Jyotish to the Applications folder and start it again.")
    }

    /// Ask GitHub for the latest release and fetch it when it is newer than this build.
    /// Ask for the latest build. The asking, fetching and checking are done by a second process (this app
    /// started as `--update-helper`), so an update arrives whether or not this window is answering.
    /// `byHand` is the Check for updates button: it says what it found even when that is nothing new.
    func check(byHand: Bool = false) {
        guard let current = Updater.build, let program = Bundle.main.executableURL else {
            if byHand { state = .failed("This copy runs from source and does not update itself.") }
            return
        }
        // what is newer is measured against the window that is running, not the copy on disk
        if let disk = Updater.onDisk(), disk > current { state = .ready(disk) }
        else if let waiting = Updater.build(of: Updater.staged), waiting > current { state = .ready(waiting) } else if byHand { state = .checking }
        let helper = Process()
        helper.executableURL = program
        helper.arguments = ["--update-helper"]
        helper.terminationHandler = { _ in
            let outcome = UpdateHelper.lastOutcome()
            Task { @MainActor in
                switch outcome {
                case .staged(let build): self.state = .ready(build)
                case .current(let build):
                    // the helper speaks for the copy on disk: when that is ahead of this window, a restart is the update
                    if build > current { self.state = .ready(build) } else if byHand { self.state = .current(current) }
                case .failed(let why): self.state = .failed(why)
                case .unreachable(let why): if byHand { self.state = .failed("GitHub could not be reached: \(why)") }
                }
            }
        }
        do { try helper.run() } catch { if byHand { state = .failed("The update helper could not be started: \(error.localizedDescription)") } }
    }
}

/// The update's own work, free of the window: ask GitHub for the latest release, fetch it when it is newer,
/// check it against its published digest, unpack it, and leave it ready for the next start.
enum UpdateHelper {
    enum Outcome: Codable, Equatable {
        case current(Int)
        case staged(Int)
        case failed(String)
        case unreachable(String)
    }

    private struct Release: Decodable {
        struct Asset: Decodable { var name: String; var browser_download_url: URL }
        var tag_name: String
        var assets: [Asset]
    }

    private static let repository = "seeker71/form-jyotish", archive = "FormJyotish.zip"
    private static var home: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FormJyotish") }
    private static var folder: URL { home.appendingPathComponent("update") }
    private static var arriving: URL { home.appendingPathComponent("update-arriving") }
    private static var note: URL { home.appendingPathComponent("update-outcome.json") }

    private static func build(of app: URL) -> Int? {
        guard let info = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist")),
              info["CFBundleIdentifier"] as? String == Bundle.main.bundleIdentifier else { return nil }
        return (info["CFBundleVersion"] as? String).flatMap(Int.init)
    }

    private struct Stalled: LocalizedError { var errorDescription: String? { "the download did not finish in time" } }

    /// One download, waited for at most three minutes. The session answers on its own queue, so the wait
    /// holds whichever thread asks, the first thread of a starting app included.
    private static func fetch(_ url: URL) throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.setValue("application/vnd.github+json, application/octet-stream", forHTTPHeaderField: "Accept")
        let done = DispatchSemaphore(value: 0)
        var result: Result<Data, Error> = .failure(Stalled())
        let task = URLSession(configuration: .ephemeral).dataTask(with: request) { data, response, error in
            if let error { result = .failure(error) }
            else if let data, (response as? HTTPURLResponse)?.statusCode == 200 { result = .success(data) }
            else { result = .failure(URLError(.badServerResponse)) }
            done.signal()
        }
        task.resume()
        if done.wait(timeout: .now() + 180) == .timedOut { task.cancel(); throw Stalled() }
        return try result.get()
    }

    /// Start the helper as its own process and wait for it, at most `seconds`: how a starting app heals.
    static func runApart(seconds: Double) -> Outcome {
        guard let program = Bundle.main.executableURL else { return .failed("no program to start") }
        try? FileManager.default.removeItem(at: note)
        let helper = Process()
        helper.executableURL = program
        helper.arguments = ["--update-helper"]
        let ended = DispatchSemaphore(value: 0)
        helper.terminationHandler = { _ in ended.signal() }
        do { try helper.run() } catch { return .failed(error.localizedDescription) }
        if ended.wait(timeout: .now() + seconds) == .timedOut { helper.terminate(); return .unreachable("the update took too long") }
        return lastOutcome()
    }

    static func lastOutcome() -> Outcome {
        (try? JSONDecoder().decode(Outcome.self, from: Data(contentsOf: note))) ?? .unreachable("the helper left no word")
    }

    /// Run the whole update and leave its outcome in a note the app reads.
    @discardableResult static func run() -> Outcome {
        let outcome = work()
        try? FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        try? JSONEncoder().encode(outcome).write(to: note)
        return outcome
    }

    private static func work() -> Outcome {
        guard Bundle.main.bundleURL.pathExtension == "app", let current = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String).flatMap(Int.init) else {
            return .failed("This copy runs from source and does not update itself.")
        }
        let files = FileManager.default
        let release: Release
        do {
            release = try JSONDecoder().decode(Release.self, from: fetch(URL(string: "https://api.github.com/repos/\(repository)/releases/latest")!))
        } catch { return .unreachable(error.localizedDescription) }
        guard release.tag_name.hasPrefix("build-"), let latest = Int(release.tag_name.dropFirst("build-".count)) else { return .failed("The latest release carries no build number.") }
        if let held = build(of: folder.appendingPathComponent("FormJyotish.app")), held > current, held >= latest { return .staged(held) }
        guard latest > current else { return .current(current) }
        guard let zip = release.assets.first(where: { $0.name == archive }), let digest = release.assets.first(where: { $0.name == archive + ".sha256" }) else {
            return .failed("Build \(latest) carries no \(archive) with its digest.")
        }
        do {
            // fetched and unpacked aside, then moved into place whole: the app never meets half an update
            try? files.removeItem(at: arriving)
            try files.createDirectory(at: arriving, withIntermediateDirectories: true)
            let expected = String(decoding: try fetch(digest.browser_download_url), as: UTF8.self).split(whereSeparator: { $0 == " " || $0 == "\n" }).first.map(String.init) ?? ""
            let bytes = try fetch(zip.browser_download_url)
            let actual = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            guard actual == expected.lowercased(), !expected.isEmpty else {
                try? files.removeItem(at: arriving)
                return .failed("Build \(latest) did not match its published digest and was discarded.")
            }
            let packed = arriving.appendingPathComponent(archive)
            try bytes.write(to: packed)
            let unzip = Process()
            unzip.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            unzip.arguments = ["-x", "-k", packed.path, arriving.path]
            try unzip.run()
            unzip.waitUntilExit()
            try? files.removeItem(at: packed)
            guard unzip.terminationStatus == 0, build(of: arriving.appendingPathComponent("FormJyotish.app")) == latest else {
                try? files.removeItem(at: arriving)
                return .failed("Build \(latest) could not be unpacked as Form Jyotish and was discarded.")
            }
            try? files.removeItem(at: folder)
            try files.moveItem(at: arriving, to: folder)
            return .staged(latest)
        } catch {
            try? files.removeItem(at: arriving)
            return .unreachable(error.localizedDescription)
        }
    }
}
