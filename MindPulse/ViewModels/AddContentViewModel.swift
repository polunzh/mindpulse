import Foundation
import SwiftData
import SwiftUI

enum AddContentFailureType {
    case urlFetch        // URL 抓取失败
    case aiTimeout       // AI 请求超时/网络异常
    case aiParseFailed   // AI 返回格式异常
}

@Observable
final class AddContentViewModel {
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var generatedCards: [PreviewCard] = []
    var showPreview: Bool = false
    var showManualCardCreation: Bool = false

    // 失败态
    var failureType: AddContentFailureType?
    var canRetry: Bool = true

    // 草稿
    var hasDraft: Bool { draftContent != nil }
    private var draftContent: String?
    private var draftSourceType: SourceType?

    private let aiService = AIService()
    private let urlParser = URLParserService()
    private var modelContext: ModelContext?
    private var currentSource: Source?
    private var aiRetryCount = 0
    private static let maxAIRetry = 1

    struct PreviewCard: Identifiable {
        let id = UUID()
        var question: String
        var answer: String
        var sourceQuote: String
        var isSelected: Bool = true
    }

    // 手动建卡
    var manualQuestion: String = ""
    var manualAnswer: String = ""

    var hasAPIKey: Bool {
        AIProviderConfig.hasAPIKey
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
        failureType = nil
        aiRetryCount = 0

        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let content: String
            var title: String?
            var domain: String?
            let sourceType: SourceType

            if isURL {
                sourceType = .url
                do {
                    let parsed = try await urlParser.extractContent(from: trimmedInput)
                    content = parsed.body
                    title = parsed.title
                    domain = parsed.domain
                } catch {
                    await MainActor.run {
                        failureType = .urlFetch
                        errorMessage = "无法抓取网页内容：\(error.localizedDescription)"
                        isLoading = false
                    }
                    return
                }
            } else {
                sourceType = .text
                content = trimmedInput
            }

            // 保存用于重试
            draftContent = content
            draftSourceType = sourceType

            // 调用 AI 生成卡片（含自动重试）
            let aiCards = try await generateCardsWithRetry(content: content)

            let source = Source(
                type: sourceType,
                rawContent: trimmedInput,
                extractedText: content,
                title: title,
                domain: domain
            )
            currentSource = source

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
                draftContent = nil
            }
        } catch let error as AIServiceError where error.isTimeout {
            await MainActor.run {
                failureType = .aiTimeout
                errorMessage = "AI 请求超时，请检查网络后重试"
                isLoading = false
            }
        } catch is DecodingError {
            await MainActor.run {
                failureType = .aiParseFailed
                errorMessage = "AI 返回格式异常，请尝试手动建卡"
                isLoading = false
            }
        } catch {
            await MainActor.run {
                failureType = .aiTimeout
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func generateCardsWithRetry(content: String) async throws -> [AIService.GeneratedCard] {
        do {
            return try await aiService.generateCards(from: content)
        } catch is DecodingError {
            // JSON 解析失败：自动重试 1 次
            if aiRetryCount < Self.maxAIRetry {
                aiRetryCount += 1
                return try await aiService.generateCards(from: content)
            }
            throw AIServiceError.parseError
        }
    }

    // MARK: - Retry

    func retry() async {
        if failureType == .urlFetch {
            // URL 失败重试：重新从头开始
            await generateCards()
        } else if let content = draftContent {
            // AI 失败重试：直接重新调 AI
            isLoading = true
            errorMessage = nil
            failureType = nil
            aiRetryCount = 0

            do {
                let aiCards = try await generateCardsWithRetry(content: content)

                let source = Source(
                    type: draftSourceType ?? .text,
                    rawContent: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
                    extractedText: content
                )
                currentSource = source

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
                    draftContent = nil
                }
            } catch {
                await MainActor.run {
                    failureType = .aiParseFailed
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        } else {
            await generateCards()
        }
    }

    // MARK: - Save to Draft

    func saveToDraft() {
        draftContent = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        draftSourceType = isURL ? .url : .text
        errorMessage = nil
        failureType = nil
    }

    func loadDraft() {
        if let draft = draftContent {
            inputText = draft
        }
    }

    // MARK: - Manual Card Creation

    func switchToManualCardCreation() {
        showManualCardCreation = true
        failureType = nil
        errorMessage = nil
    }

    func saveManualCard() {
        guard let modelContext else { return }
        guard !manualQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !manualAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 创建一个简单的 Source
        let source = Source(
            type: .text,
            rawContent: inputText.isEmpty ? manualQuestion : inputText,
            extractedText: manualQuestion
        )
        modelContext.insert(source)

        let card = Card(
            question: manualQuestion.trimmingCharacters(in: .whitespacesAndNewlines),
            answer: manualAnswer.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceQuote: "",
            source: source
        )
        modelContext.insert(card)

        do {
            try modelContext.save()
            manualQuestion = ""
            manualAnswer = ""
            showManualCardCreation = false
            reset()
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Switch to manual paste (URL fallback)

    func switchToManualPaste() {
        failureType = nil
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

        modelContext.insert(source)

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
        showManualCardCreation = false
        errorMessage = nil
        failureType = nil
        currentSource = nil
        manualQuestion = ""
        manualAnswer = ""
    }

    // MARK: - Clipboard Detection

    func checkClipboard() -> String? {
        guard let content = UIPasteboard.general.string else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

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
