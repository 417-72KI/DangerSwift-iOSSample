let logger = Logger()

final class Logger {
    fileprivate init() {}

    var logLevel: Level = .debug

    func debug(_ obj: Any, functionName: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        logln(.debug, obj, functionName: functionName, file: file, line: line)
    }

    func info(_ obj: Any, functionName: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        logln(.info, obj, functionName: functionName, file: file, line: line)
    }

    func error(_ obj: Any, functionName: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
        logln(.error, obj, functionName: functionName, file: file, line: line)
    }
}

private extension Logger {
    func logln(_ level: Level, _ obj: Any, functionName: StaticString, file: StaticString, line: UInt) {
        guard level >= logLevel else { return }
        print("[\(level)] \(file):\(line) \(functionName)> \(obj)")
    }
}

extension Logger {
    enum Level: Int, CaseIterable {
        case verbose
        case debug
        case info
        case notice
        case warning
        case error
    }
}

extension Logger.Level: Comparable {
    static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Logger.Level: CustomStringConvertible {
    var description: String {
        switch self {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .notice:
            return "NOTICE"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }
}
