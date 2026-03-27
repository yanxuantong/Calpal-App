import Foundation

enum AppLaunchMode: String {
    case dashboard
    case smartScheduling = "smart_scheduling"

    static var current: AppLaunchMode? {
        let environment = ProcessInfo.processInfo.environment

        if let rawValue = environment["CALPAL_SHOWCASE_SCREEN"],
           let mode = AppLaunchMode(rawValue: rawValue) {
            return mode
        }

        for argument in ProcessInfo.processInfo.arguments {
            guard let value = argument.split(separator: "=").last,
                  argument.hasPrefix("--showcase-screen="),
                  let mode = AppLaunchMode(rawValue: String(value)) else {
                continue
            }
            return mode
        }

        return nil
    }
}
