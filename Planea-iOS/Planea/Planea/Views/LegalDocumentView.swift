import SwiftUI
import WebKit

struct LegalDocumentView: View {
    let documentType: LegalDocumentType
    @Environment(\.dismiss) private var dismiss
    @State private var htmlContent: String = ""
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    WebView(htmlContent: htmlContent)
                }
            }
            .navigationTitle(documentType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDocument()
            }
        }
    }
    
    private func loadDocument() {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        
        LegalDocumentService.shared.loadDocument(type: documentType, language: language) { result in
            switch result {
            case .success(let content):
                htmlContent = content
            case .failure:
                // Fallback to simple text content
                htmlContent = createSimpleHTML(content: documentType.content)
            }
            isLoading = false
        }
    }
    
    private func createSimpleHTML(content: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    padding: 20px;
                    line-height: 1.6;
                    color: #333;
                }
            </style>
        </head>
        <body>
            <p>\(content)</p>
        </body>
        </html>
        """
    }
}

struct WebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

enum LegalDocumentType {
    case termsAndConditions
    case privacyPolicy
    
    var title: String {
        switch self {
        case .termsAndConditions:
            return "legal.terms.title".localized
        case .privacyPolicy:
            return "legal.privacy.title".localized
        }
    }
    
    var content: String {
        switch self {
        case .termsAndConditions:
            return "legal.terms.content".localized
        case .privacyPolicy:
            return "legal.privacy.content".localized
        }
    }
}
