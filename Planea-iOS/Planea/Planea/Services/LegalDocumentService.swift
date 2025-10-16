import Foundation

class LegalDocumentService {
    static let shared = LegalDocumentService()
    
    // Base URL for GitHub Pages - UPDATE THIS after deploying to GitHub Pages
    private let baseURL = "https://VOTRE-USERNAME.github.io/planea-legal"
    
    // Cache directory
    private let cacheDirectory: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("LegalDocuments")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
    
    private init() {}
    
    /// Loads a legal document with caching and fallback support
    /// - Parameters:
    ///   - type: The type of legal document to load
    ///   - language: The language code (e.g., "fr" or "en")
    ///   - completion: Completion handler with the document content
    func loadDocument(type: LegalDocumentType, language: String, completion: @escaping (Result<String, Error>) -> Void) {
        let filename = "\(type.filename)-\(language).html"
        let url = URL(string: "\(baseURL)/\(filename)")!
        let cacheURL = cacheDirectory.appendingPathComponent(filename)
        
        // Try to load from network first
        loadFromNetwork(url: url) { [weak self] result in
            switch result {
            case .success(let content):
                // Save to cache
                self?.saveToCache(content: content, at: cacheURL)
                completion(.success(content))
                
            case .failure:
                // Try to load from cache
                if let cachedContent = self?.loadFromCache(at: cacheURL) {
                    completion(.success(cachedContent))
                } else {
                    // Fallback to hardcoded content
                    let fallbackContent = self?.getFallbackContent(type: type, language: language) ?? ""
                    completion(.success(fallbackContent))
                }
            }
        }
    }
    
    /// Loads a legal document synchronously for offline use
    func loadDocumentSync(type: LegalDocumentType, language: String) -> String {
        let filename = "\(type.filename)-\(language).html"
        let cacheURL = cacheDirectory.appendingPathComponent(filename)
        
        // Try cache first
        if let cachedContent = loadFromCache(at: cacheURL) {
            return cachedContent
        }
        
        // Fallback to hardcoded content
        return getFallbackContent(type: type, language: language)
    }
    
    // MARK: - Private Methods
    
    private func loadFromNetwork(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let content = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "LegalDocumentService", code: -1)))
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(content))
            }
        }
        task.resume()
    }
    
    private func saveToCache(content: String, at url: URL) {
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func loadFromCache(at url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }
    
    private func getFallbackContent(type: LegalDocumentType, language: String) -> String {
        // Fallback to the original localized strings
        switch type {
        case .termsAndConditions:
            return String(localized: "legal.terms.content")
        case .privacyPolicy:
            return String(localized: "legal.privacy.content")
        }
    }
    
    /// Preload documents for offline use
    func preloadDocuments() {
        let languages = ["fr", "en"]
        let types: [LegalDocumentType] = [.termsAndConditions, .privacyPolicy]
        
        for language in languages {
            for type in types {
                loadDocument(type: type, language: language) { _ in
                    // Documents are now cached
                }
            }
        }
    }
    
    /// Clear all cached documents
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// Extension to add filename property
extension LegalDocumentType {
    var filename: String {
        switch self {
        case .termsAndConditions:
            return "terms"
        case .privacyPolicy:
            return "privacy"
        }
    }
}
