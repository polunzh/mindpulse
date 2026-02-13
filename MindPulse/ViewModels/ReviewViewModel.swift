import Foundation
import SwiftData
import SwiftUI

@Observable
final class ReviewViewModel {
    var todayCards: [Card] = []
    var currentIndex: Int = 0
    var isFlipped: Bool = false
    var isCompleted: Bool = false
    var showStatusRecord: Bool = false

    // 复习统计
    var reviewedCount: Int = 0
    var rememberedCount: Int = 0

    // 状态记录
    var energyLevel: Double = 5.0
    var statusKeyword: String = ""
    var showUndoBanner: Bool = false

    // 撤回上一张卡片
    var showCardUndoBanner: Bool = false
    private var lastReviewedCard: Card?
    private var lastReviewResult: ReviewResult?
    private var lastReviewLog: ReviewLog?
    // SM-2 状态快照（用于撤回恢复）
    private var lastCardSnapshot: (repetition: Int, easeFactor: Double, interval: Int, nextReviewDate: Date)?
    private var cardUndoTimer: DispatchWorkItem?

    // 滑动状态
    var dragOffset: CGSize = .zero

    private let reviewEngine = ReviewEngine()
    private var modelContext: ModelContext?

    var currentCard: Card? {
        guard currentIndex < todayCards.count else { return nil }
        return todayCards[currentIndex]
    }

    var progress: Double {
        guard !todayCards.isEmpty else { return 0 }
        return Double(reviewedCount) / Double(todayCards.count)
    }

    var retentionRate: Double {
        guard reviewedCount > 0 else { return 0 }
        return Double(rememberedCount) / Double(reviewedCount)
    }

    var hasCardsToReview: Bool {
        !todayCards.isEmpty && !isCompleted
    }

    // MARK: - Setup

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadTodayCards(modelContext: ModelContext) {
        self.modelContext = modelContext

        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate<Card> { $0.isActive }
        )

        do {
            let allCards = try modelContext.fetch(descriptor)
            todayCards = reviewEngine.selectTodayCards(from: allCards)
            currentIndex = 0
            reviewedCount = 0
            rememberedCount = 0
            isCompleted = false
            isFlipped = false
        } catch {
            todayCards = []
        }
    }

    // MARK: - Card Interaction

    func flipCard() {
        withAnimation(.easeInOut(duration: 0.4)) {
            isFlipped = true
        }
    }

    func swipeCard(result: ReviewResult) {
        guard let card = currentCard, let modelContext else { return }

        // 清除上一次的撤回状态
        dismissCardUndo()

        // 保存快照用于撤回
        lastCardSnapshot = (
            repetition: card.repetition,
            easeFactor: card.easeFactor,
            interval: card.interval,
            nextReviewDate: card.nextReviewDate
        )
        lastReviewedCard = card
        lastReviewResult = result

        // 更新 SM-2 状态
        reviewEngine.processReview(card: card, result: result)

        // 记录复习日志
        let log = ReviewLog(card: card, result: result)
        modelContext.insert(log)
        lastReviewLog = log

        reviewedCount += 1
        if result == .remembered {
            rememberedCount += 1
        }

        // 下一张或完成
        if currentIndex + 1 < todayCards.count {
            currentIndex += 1
            isFlipped = false

            // 显示 5 秒撤回提示
            showCardUndoBanner = true
            let timer = DispatchWorkItem { [weak self] in
                self?.showCardUndoBanner = false
                self?.clearCardUndoState()
            }
            cardUndoTimer = timer
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: timer)
        } else {
            isCompleted = true
            showStatusRecord = true
        }

        try? modelContext.save()
    }

    // MARK: - Undo Last Card

    func undoLastCard() {
        guard let modelContext,
              let card = lastReviewedCard,
              let snapshot = lastCardSnapshot,
              let log = lastReviewLog else { return }

        // 恢复 SM-2 状态
        card.repetition = snapshot.repetition
        card.easeFactor = snapshot.easeFactor
        card.interval = snapshot.interval
        card.nextReviewDate = snapshot.nextReviewDate

        // 删除复习日志
        modelContext.delete(log)

        // 恢复统计
        reviewedCount -= 1
        if lastReviewResult == .remembered {
            rememberedCount -= 1
        }

        // 回到上一张
        currentIndex -= 1
        isFlipped = false

        try? modelContext.save()

        dismissCardUndo()
        clearCardUndoState()
    }

    private func dismissCardUndo() {
        cardUndoTimer?.cancel()
        cardUndoTimer = nil
        showCardUndoBanner = false
    }

    private func clearCardUndoState() {
        lastReviewedCard = nil
        lastReviewResult = nil
        lastReviewLog = nil
        lastCardSnapshot = nil
    }

    // MARK: - Status Record

    func saveStatus() {
        guard let modelContext else { return }

        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<DailyStatus>(
            predicate: #Predicate<DailyStatus> { status in
                status.date == today
            }
        )

        do {
            let existing = try modelContext.fetch(descriptor)
            if let status = existing.first {
                status.energyLevel = energyLevel
                status.keyword = statusKeyword.isEmpty ? nil : statusKeyword
                status.cardsReviewed = reviewedCount
                status.cardsRemembered = rememberedCount
            } else {
                let status = DailyStatus(
                    date: today,
                    energyLevel: energyLevel,
                    keyword: statusKeyword.isEmpty ? nil : statusKeyword,
                    cardsReviewed: reviewedCount,
                    cardsRemembered: rememberedCount
                )
                modelContext.insert(status)
            }
            try modelContext.save()

            // 显示撤回按钮 5 秒
            showUndoBanner = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.showUndoBanner = false
            }

            showStatusRecord = false
        } catch {
            // 静默处理
        }
    }

    func undoStatus() {
        guard let modelContext else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyStatus>(
            predicate: #Predicate<DailyStatus> { status in
                status.date == today
            }
        )

        do {
            let existing = try modelContext.fetch(descriptor)
            if let status = existing.first {
                modelContext.delete(status)
                try modelContext.save()
            }
            showUndoBanner = false
            showStatusRecord = true
        } catch {
            // 静默处理
        }
    }

    func skipStatus() {
        showStatusRecord = false
    }

    // MARK: - Quick Tags

    static let quickTags = ["充实", "疲惫", "焦虑", "平静", "兴奋", "专注"]
}
