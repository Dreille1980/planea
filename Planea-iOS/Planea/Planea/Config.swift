import Foundation

struct Config {
    static var baseURL: String {
        #if DEBUG
        // Use localhost for development to avoid SSL issues with corporate proxies (Zscaler)
        return "http://localhost:8000"
        #else
        // Use Render server for production App Store builds
        return "https://planea-backend.onrender.com"
        #endif
    }
}
