import Foundation

/// AI 卡片生成和洞察服务（多模型支持）
final class AIService {
    // 保留旧 key 以向后兼容
    static let apiKeyKey = AIProviderConfig.currentProvider.apiKeySettingKey

    private let providers: [AIProviderType: AIProvider] = [
        .claude: ClaudeProvider(),
        .openAI: OpenAIProvider(),
        .deepSeek: DeepSeekProvider(),
        .gemini: GeminiProvider()
    ]

    struct GeneratedCard: Codable {
        let question: String
        let answer: String
        let source_quote: String
    }

    struct AIInsight: Codable {
        let insights: [String]
    }

    // MARK: - Card Generation

    func generateCards(from content: String) async throws -> [GeneratedCard] {
        let prompt = """
        你是一个知识提炼专家。请阅读以下内容，提取 3-5 个最有价值的知识点，生成间隔重复卡片。

        要求：
        1. 每张卡片包含：问题（正面）、答案（背面）、原文引用（一句话）
        2. 问题要具体，避免"是什么"这类空泛问题
        3. 优先提取：反直觉的观点、可操作的方法论、关键数据
        4. 答案控制在 2-3 句话内
        5. 用中文输出

        输出纯 JSON 数组格式，不要包含 markdown 代码块标记：
        [
          {
            "question": "...",
            "answer": "...",
            "source_quote": "..."
          }
        ]

        以下是内容：
        ---
        \(content)
        ---
        """

        let responseText = try await callAI(prompt: prompt)
        return try parseCards(from: responseText)
    }

    // MARK: - Weekly Insight Generation

    func generateInsights(from weeklyStats: WeeklyStats) async throws -> [String] {
        let statsJSON = try JSONEncoder().encode(weeklyStats)
        let statsString = String(data: statsJSON, encoding: .utf8) ?? "{}"

        let prompt = """
        你是一个数据分析师和行为教练。以下是用户过去一周的学习和状态数据。
        请生成 2-3 条洞察，要求：
        1. 找到知识学习和能量状态之间的关联
        2. 给出具体可操作的建议
        3. 语气温和友好，不要说教
        4. 每条洞察 1-2 句话

        输出纯 JSON 格式，不要包含 markdown 代码块标记：
        {"insights": ["洞察1", "洞察2", "洞察3"]}

        数据：
        \(statsString)
        """

        let responseText = try await callAI(prompt: prompt)
        let data = Data(responseText.utf8)
        let result = try JSONDecoder().decode(AIInsight.self, from: data)
        return result.insights
    }

    // MARK: - Unified AI Call

    private func callAI(prompt: String) async throws -> String {
        let providerType = AIProviderConfig.currentProvider
        let apiKey = AIProviderConfig.currentAPIKey
        let model = AIProviderConfig.currentModel

        guard !apiKey.isEmpty else {
            throw AIServiceError.noAPIKey
        }

        guard let provider = providers[providerType] else {
            throw AIServiceError.invalidResponse
        }

        do {
            return try await provider.sendMessage(prompt: prompt, model: model, apiKey: apiKey)
        } catch let error as URLError where error.code == .timedOut {
            throw AIServiceError.timeout
        }
    }

    // MARK: - Parse Cards

    private func parseCards(from text: String) throws -> [GeneratedCard] {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 移除可能的 markdown 代码块标记
        if jsonString.hasPrefix("```") {
            let lines = jsonString.components(separatedBy: "\n")
            let filtered = lines.dropFirst().dropLast()
            jsonString = filtered.joined(separator: "\n")
        }

        // 尝试从文本中提取 JSON 数组（处理模型可能返回前后额外文本的情况）
        if let start = jsonString.firstIndex(of: "["),
           let end = jsonString.lastIndex(of: "]") {
            jsonString = String(jsonString[start...end])
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw AIServiceError.parseError
        }

        return try JSONDecoder().decode([GeneratedCard].self, from: data)
    }
}

// MARK: - Weekly Stats Model

struct WeeklyStats: Codable {
    let startDate: String
    let endDate: String
    let totalCardsReviewed: Int
    let totalCardsRemembered: Int
    let retentionRate: Double
    let averageEnergy: Double
    let dailyDetails: [DailyDetail]

    struct DailyDetail: Codable {
        let date: String
        let cardsReviewed: Int
        let cardsRemembered: Int
        let energyLevel: Double?
        let keyword: String?
    }
}

// MARK: - Errors

enum AIServiceError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    case timeout

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "请先在设置中配置 API Key"
        case .invalidResponse:
            return "AI 服务返回了无效的响应"
        case .apiError(let code, let message):
            return "AI 服务错误 (\(code)): \(message)"
        case .parseError:
            return "无法解析 AI 生成的卡片"
        case .timeout:
            return "AI 请求超时，请检查网络连接"
        }
    }

    var isTimeout: Bool {
        switch self {
        case .timeout: return true
        case .apiError(let code, _): return code == 408 || code == 529
        default: return false
        }
    }
}
