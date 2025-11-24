import Foundation

class LocalizationHelper {
    static var shared = LocalizationHelper()
    
    var currentLanguage: String {
        get {
            UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "appLanguage")
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    var bundle: Bundle {
        let language = AppLanguage(rawValue: currentLanguage) ?? .system
        let languageCode: String
        
        switch language {
        case .system:
            languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        case .fr:
            languageCode = "fr"
        case .en:
            languageCode = "en"
        }
        
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        
        return Bundle.main
    }
    
    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    static func currentLanguageCode() -> String {
        let language = AppLanguage(rawValue: shared.currentLanguage) ?? .system
        
        switch language {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .fr:
            return "fr"
        case .en:
            return "en"
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// Extension to make it easy to use
extension String {
    var localized: String {
        return LocalizationHelper.shared.localizedString(self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: localized, arguments: arguments)
    }
}
