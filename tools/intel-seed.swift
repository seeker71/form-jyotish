// Write a copy of the kernel's runtime source that runs on an Intel Mac.
//
//   swift tools/intel-seed.swift <kernel>/runtime/fkwu-uni.c out.c
//
// The runtime's float lane writes arm64 machine words, and only a Darwin arm64 build has a page to
// land them on. On an Intel Mac the lane's admission still ran, and ended a long numeric run with a
// fault (seen in the transit door). The copy closes the lane's two entries off Darwin arm64, where the
// walker answers every call. When the kernel's own source carries this guard, this tool leaves.
import Foundation
let source = CommandLine.arguments[1], target = CommandLine.arguments[2]
var text = try! String(contentsOfFile: source, encoding: .utf8)
if text.contains("the float lane emits arm64 words") { try! text.write(toFile: target, atomically: true, encoding: .utf8); exit(0) }
let entries = [("static void fk_f64_pulse(long long fx) {\n", "(void)fx;"),
               ("static void fk_f64_loop_pulse(long long fx, long long fp, long long n) {\n", "(void)fx; (void)fp; (void)n;")]
for (head, unused) in entries {
    guard let opening = text.range(of: head), let closing = text.range(of: "\n}\n", range: opening.upperBound..<text.endIndex) else {
        FileHandle.standardError.write(Data("intel-seed: the runtime no longer holds \(head)".utf8)); exit(1)
    }
    text.replaceSubrange(closing, with: "\n#endif\n}\n")
    text.replaceSubrange(opening, with: head + "#if !defined(FK_HAVE_DARWIN_ARM64_JIT_WITNESS)\n    /* the float lane emits arm64 words: off Darwin arm64 the walker answers */\n    \(unused) return;\n#else\n")
}
try! text.write(toFile: target, atomically: true, encoding: .utf8)
