import Foundation

/// 从 URL 提取网页正文
final class URLParserService {

    struct ParsedContent {
        let title: String
        let body: String
        let domain: String?
    }

    func extractContent(from urlString: String) async throws -> ParsedContent {
        guard let url = URL(string: urlString) else {
            throw URLParserError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLParserError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .ascii) else {
            throw URLParserError.encodingError
        }

        let title = extractTitle(from: html)
        let body = extractBody(from: html)
        let domain = url.host

        guard !body.isEmpty else {
            throw URLParserError.noContent
        }

        return ParsedContent(title: title, body: body, domain: domain)
    }

    // MARK: - HTML Parsing (lightweight, no external dependency)

    private func extractTitle(from html: String) -> String {
        // 提取 <title> 标签内容
        if let titleRange = html.range(of: "<title[^>]*>(.*?)</title>",
                                        options: .regularExpression,
                                        range: html.startIndex..<html.endIndex) {
            let titleHTML = String(html[titleRange])
            return stripHTMLTags(titleHTML)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 尝试 og:title
        if let ogTitle = extractMetaContent(from: html, property: "og:title") {
            return ogTitle
        }

        return "未知标题"
    }

    private func extractBody(from html: String) -> String {
        var text = html

        // 移除 script 和 style
        text = text.replacingOccurrences(
            of: "<script[^>]*>[\\s\\S]*?</script>",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "<style[^>]*>[\\s\\S]*?</style>",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "<nav[^>]*>[\\s\\S]*?</nav>",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "<header[^>]*>[\\s\\S]*?</header>",
            with: "",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "<footer[^>]*>[\\s\\S]*?</footer>",
            with: "",
            options: .regularExpression
        )

        // 尝试提取 article 或 main 标签内容
        if let articleContent = extractTag(from: text, tag: "article") {
            text = articleContent
        } else if let mainContent = extractTag(from: text, tag: "main") {
            text = mainContent
        }

        // 用换行替换 <p>, <br>, <div> 等块级标签
        text = text.replacingOccurrences(
            of: "<(p|br|div|h[1-6]|li)[^>]*>",
            with: "\n",
            options: .regularExpression
        )

        // 移除所有 HTML 标签
        text = stripHTMLTags(text)

        // 解码 HTML 实体
        text = decodeHTMLEntities(text)

        // 清理多余空白
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let result = lines.joined(separator: "\n")

        // 限制长度，避免发送过多内容给 AI
        if result.count > 5000 {
            return String(result.prefix(5000))
        }
        return result
    }

    private func extractTag(from html: String, tag: String) -> String? {
        let pattern = "<\(tag)[^>]*>([\\s\\S]*?)</\(tag)>"
        guard let range = html.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        return String(html[range])
    }

    private func extractMetaContent(from html: String, property: String) -> String? {
        let pattern = "<meta[^>]*property=\"\(property)\"[^>]*content=\"([^\"]*)\""
        guard let range = html.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        let match = String(html[range])
        if let contentRange = match.range(of: "content=\"([^\"]*)\"", options: .regularExpression) {
            let content = String(match[contentRange])
            return content
                .replacingOccurrences(of: "content=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
        }
        return nil
    }

    private func stripHTMLTags(_ string: String) -> String {
        string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&#39;": "'", "&nbsp;": " ",
            "&mdash;": "—", "&ndash;": "–", "&hellip;": "…"
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
}

enum URLParserError: LocalizedError {
    case invalidURL
    case fetchFailed
    case encodingError
    case noContent

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .fetchFailed: return "无法获取网页内容"
        case .encodingError: return "网页编码无法识别"
        case .noContent: return "未能提取到正文内容，请尝试手动粘贴"
        }
    }
}
