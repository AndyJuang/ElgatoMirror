import Foundation

enum Logger {
    private static let logURL: URL = {
        let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("ElgatoMirror.log")
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return f
    }()

    static func log(_ message: String, file: String = #file, line: Int = #line) {
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let entry = "[\(timestamp)] [\(filename):\(line)] \(message)\n"

        print(entry, terminator: "")

        guard let data = entry.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: logURL, options: .atomic)
        }
    }

    static func logError(_ error: Error, context: String, file: String = #file, line: Int = #line) {
        let nsErr = error as NSError
        let detail = "domain=\(nsErr.domain) code=\(nsErr.code) desc=\"\(error.localizedDescription)\" userInfo=\(nsErr.userInfo)"
        log("ERROR [\(context)]: \(detail)", file: file, line: line)
    }

    /// 清除舊 log（超過 500 行時刪除前半）
    static func rotate() {
        guard let content = try? String(contentsOf: logURL, encoding: .utf8) else { return }
        let lines = content.components(separatedBy: "\n")
        guard lines.count > 500 else { return }
        let trimmed = lines.dropFirst(lines.count / 2).joined(separator: "\n")
        try? trimmed.write(to: logURL, atomically: true, encoding: .utf8)
    }
}
