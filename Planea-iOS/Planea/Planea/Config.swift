import Foundation

struct Config {
    static var baseURL: String {
        #if DEBUG
        return "http://localhost:8000"
        #else
        return "https://planea-production.up.railway.app"
        #endif
    }
}
