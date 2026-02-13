import Foundation
import SwiftData
import SwiftUI

@Observable
final class AddContentViewModel {
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var generatedCards: [PreviewCard] = []
    var showPreview: Bool = false
    var showURLFallback: Bool = false

    private let aiService = AIService()
    private let urlParser = URLParserService()
    private var modelContext: ModelContext?
    private var currentSource: Source?

    struct PreviewCard: Identifiable {
        let id = UUID()
        var question: String
        var answer: String
        var sourceQuote: String
        var isSelected: Bool = true
    }

    var hasAPIKey: Bool {
        let key = UserDefaults.standard.string(forKey: AIService.apiKeyKey) ?? ""
        return !key.isEmpty
    }

    var isInputValid: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isURL: Bool {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Generate Cards

    func generateCards() async {
        guard isInputValid else { return }

        isLoading = true
        errorMessage = nil
        showURLFallback = false

        do {
            let content: String
            var title: String?
            var domain: String?
            let sourceType: SourceType

            let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

            if isURL {
                sourceType = .url
                do {
                    let parsed = try await urlParser.extractContent(from: trimmedInput)
                    content = parsed.body
                    title = parsed.title
                    domain = parsed.domain
                } catch {
                    // URL 抓取失败，显示降级选项
                    await MainActor.run {
                        showURLFallback = true
                        errorMessage = "无法抓取网页内容：\(error.localizedDescription)"
                        isLoading = false
                    }
                    return
                }
            } else {
                sourceType = .text
                content = trimmedInput
            }

            // 调用 AI 生成卡片
            let aiCards = try await aiService.generateCards(from: content)

            // 创建 Source
            let source = Source(
                type: sourceType,
                rawContent: trimmedInput,
                extractedText: content,
                title: title,
                domain: domain
            )
            currentSource = source

            // 转换为预览卡片
            let previews = aiCards.map { card in
                PreviewCard(
                    question: card.question,
                    answer: card.answer,
                    sourceQuote: card.source_quote
                )
            }

            await MainActor.run {
                generatedCards = previews
                showPreview = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Switch to manual paste (URL fallback)

    func switchToManualPaste() {
        showURLFallback = false
        errorMessage = nil
        inputText = ""
    }

    // MARK: - Toggle Card Selection

    func toggleCard(at index: Int) {
        guard index < generatedCards.count else { return }
        generatedCards[index].isSelected.toggle()
    }

    // MARK: - Save Cards

    func saveSelectedCards() {
        guard let modelContext, let source = currentSource else { return }

        let selectedCards = generatedCards.filter { $0.isSelected }
        guard !selectedCards.isEmpty else { return }

        // 插入 Source
        modelContext.insert(source)

        // 插入选中的卡片
        for preview in selectedCards {
            let card = Card(
                question: preview.question,
                answer: preview.answer,
                sourceQuote: preview.sourceQuote,
                source: source
            )
            modelContext.insert(card)
        }

        do {
            try modelContext.save()
            reset()
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Reset

    func reset() {
        inputText = ""
        generatedCards = []
        showPreview = false
        showURLFallback = false
        errorMessage = nil
        currentSource = nil
    }

    // MARK: - Clipboard Detection

    func checkClipboard() -> String? {
        guard let content = UIPasteboard.general.string else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // 检查是否是 URL 或至少 50 字的文本
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        if trimmed.count >= 50 {
            return trimmed
        }
        return nil
    }

    func useClipboardContent(_ content: String) {
        inputText = content
    }
}
