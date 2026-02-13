import Foundation
import SwiftData

/// SM-2 间隔重复算法引擎
final class ReviewEngine {
    private let maxDailyCards = 8
    private let minDailyCards = 3

    /// 根据用户回答更新卡片的 SM-2 状态
    func processReview(card: Card, result: ReviewResult) {
        switch result {
        case .remembered:
            if card.repetition == 0 {
                card.interval = 1
            } else if card.repetition == 1 {
                card.interval = 6
            } else {
                card.interval = Int(round(Double(card.interval) * card.easeFactor))
            }
            card.repetition += 1
            card.easeFactor = max(1.3, card.easeFactor + 0.1)

        case .forgot:
            card.repetition = 0
            card.interval = 1
            card.easeFactor = max(1.3, card.easeFactor - 0.2)
        }

        card.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: card.interval,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
    }

    /// 选择今天需要复习的卡片
    func selectTodayCards(from allCards: [Card]) -> [Card] {
        let today = Calendar.current.startOfDay(for: Date())

        // 到期卡片：next_review_date <= 今天
        let dueCards = allCards
            .filter { $0.isActive && $0.nextReviewDate <= today }
            .sorted { card1, card2 in
                // 过期天数多的优先
                let days1 = Calendar.current.dateComponents([.day], from: card1.nextReviewDate, to: today).day ?? 0
                let days2 = Calendar.current.dateComponents([.day], from: card2.nextReviewDate, to: today).day ?? 0
                if days1 != days2 { return days1 > days2 }
                // ease_factor 低的优先（更难的卡片）
                return card1.easeFactor < card2.easeFactor
            }

        var selected = Array(dueCards.prefix(maxDailyCards))

        // 如果到期卡片不足，从最新未复习的卡片补充
        if selected.count < minDailyCards {
            let newCards = allCards
                .filter { card in card.isActive && card.repetition == 0 && !selected.contains(where: { s in s.id == card.id }) }
                .sorted { $0.createdAt > $1.createdAt }

            let needed = minDailyCards - selected.count
            selected.append(contentsOf: newCards.prefix(needed))
        }

        return selected
    }

    /// 计算记忆留存率
    func retentionRate(from logs: [ReviewLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        let remembered = logs.filter { $0.result == .remembered }.count
        return Double(remembered) / Double(logs.count)
    }
}
