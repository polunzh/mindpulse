import Foundation

/// AI 服务商枚举
enum AIProviderType: String, CaseIterable, Codable {
    case claude = "Claude"
    case openAI = "OpenAI"
    case deepSeek = "DeepSeek"
    case gemini = "Gemini"

    var displayName: String { rawValue }

    var defaultModel: String {
        switch self {
        case .claude: return "claude-sonnet-4-5-20250929"
        case .openAI: return "gpt-4o"
        case .deepSeek: return "deepseek-chat"
        case .gemini: return "gemini-2.0-flash"
        }
    }

    var availableModels: [String] {
        switch self {
        case .claude:
            return ["claude-sonnet-4-5-20250929", "claude-haiku-4-5-20251001"]
        case .openAI:
            return ["gpt-4o", "gpt-4o-mini"]
        case .deepSeek:
            return ["deepseek-chat", "deepseek-reasoner"]
        case .gemini:
            return ["gemini-2.0-flash", "gemini-2.5-pro-exp-03-25"]
        }
    }

    var apiKeyPlaceholder: String {
        switch self {
        case .claude: return "sk-ant-..."
        case .openAI: return "sk-..."
        case .deepSeek: return "sk-..."
        case .gemini: return "AIza..."
        }
    }

    var apiKeySettingKey: String {
        "\(rawValue.lowercased())_api_key"
    }
}

/// AI Provider 协议，所有模型服务商实现此接口
protocol AIProvider {
    var providerType: AIProviderType { get }
    func sendMessage(prompt: String, model: String, apiKey: String) async throws -> String
}

/// Provider 配置管理
struct AIProviderConfig {
    static let selectedProviderKey = "selected_ai_provider"
    static let selectedModelKey = "selected_ai_model"

    static var currentProvider: AIProviderType {
        get {
            guard let raw = UserDefaults.standard.string(forKey: selectedProviderKey),
                  let provider = AIProviderType(rawValue: raw) else {
                return .claude
            }
            return provider
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: selectedProviderKey)
        }
    }

    static var currentModel: String {
        get {
            UserDefaults.standard.string(forKey: selectedModelKey) ?? currentProvider.defaultModel
        }
        set {
            UserDefaults.standard.set(newValue, forKey: selectedModelKey)
        }
    }

    static var currentAPIKey: String {
        get {
            UserDefaults.standard.string(forKey: currentProvider.apiKeySettingKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: currentProvider.apiKeySettingKey)
        }
    }

    static var hasAPIKey: Bool {
        !currentAPIKey.isEmpty
    }

    static func apiKey(for provider: AIProviderType) -> String {
        UserDefaults.standard.string(forKey: provider.apiKeySettingKey) ?? ""
    }

    static func setAPIKey(_ key: String, for provider: AIProviderType) {
        UserDefaults.standard.set(key, forKey: provider.apiKeySettingKey)
    }
}
