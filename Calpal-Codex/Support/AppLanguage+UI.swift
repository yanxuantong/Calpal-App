import Foundation

extension AppLanguage {
    func ui(_ chinese: String, _ english: String) -> String {
        switch self {
        case .chinese:
            return chinese
        case .english:
            return english
        }
    }
}
