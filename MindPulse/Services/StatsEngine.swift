import Foundation
import SwiftData

/// 统计计算引擎
final class StatsEngine {

    // MARK: - Weekly Stats

    func generateWeeklyStats(
        reviewLogs: [ReviewLog],
        dailyStatuses: [DailyStatus],
        from startDate: Date,
        to endDate: Date
    ) -> WeeklyStats {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // 按天分组复习记录
        var dailyDetails: [WeeklyStats.DailyDetail] = []
        var totalReviewed = 0
        var totalRemembered = 0
        var energySum = 0.0
        var energyCount = 0

        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayLogs = reviewLogs.filter {
                $0.reviewedAt >= dayStart && $0.reviewedAt < dayEnd
            }

            let dayStatus = dailyStatuses.first {
                calendar.isDate($0.date, inSameDayAs: currentDate)
            }

            let reviewed = dayLogs.count
            let remembered = dayLogs.filter { $0.result == .remembered }.count
            totalReviewed += reviewed
            totalRemembered += remembered

            if let status = dayStatus {
                energySum += status.energyLevel
                energyCount += 1
            }

            dailyDetails.append(WeeklyStats.DailyDetail(
                date: formatter.string(from: currentDate),
                cardsReviewed: reviewed,
                cardsRemembered: remembered,
                energyLevel: dayStatus?.energyLevel,
                keyword: dayStatus?.keyword
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        let retentionRate = totalReviewed > 0
            ? Double(totalRemembered) / Double(totalReviewed)
            : 0

        let averageEnergy = energyCount > 0
            ? energySum / Double(energyCount)
            : 0

        return WeeklyStats(
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate),
            totalCardsReviewed: totalReviewed,
            totalCardsRemembered: totalRemembered,
            retentionRate: retentionRate,
            averageEnergy: averageEnergy,
            dailyDetails: dailyDetails
        )
    }

    // MARK: - Streak Calculation

    func currentStreak(from dailyStatuses: [DailyStatus]) -> Int {
        let calendar = Calendar.current
        let sorted = dailyStatuses
            .sorted { $0.date > $1.date }

        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        for status in sorted {
            let statusDay = calendar.startOfDay(for: status.date)
            if statusDay == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if statusDay < expectedDate {
                break
            }
        }

        return streak
    }

    // MARK: - Topic Distribution

    func topicDistribution(from sources: [Source]) -> [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        for source in sources {
            for tag in source.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        return tagCounts
            .sorted { $0.value > $1.value }
            .map { (tag: $0.key, count: $0.value) }
    }

    // MARK: - Energy-Retention Correlation

    struct EnergyRetentionCorrelation {
        let highEnergyRetention: Double   // 能量 ≥ 7 时的留存率
        let lowEnergyRetention: Double    // 能量 < 7 时的留存率
        let hasEnoughData: Bool
    }

    func energyRetentionCorrelation(
        reviewLogs: [ReviewLog],
        dailyStatuses: [DailyStatus]
    ) -> EnergyRetentionCorrelation {
        let calendar = Calendar.current

        var highEnergyRemembered = 0
        var highEnergyTotal = 0
        var lowEnergyRemembered = 0
        var lowEnergyTotal = 0

        for log in reviewLogs {
            let logDay = calendar.startOfDay(for: log.reviewedAt)
            guard let status = dailyStatuses.first(where: {
                calendar.isDate($0.date, inSameDayAs: logDay)
            }) else { continue }

            if status.energyLevel >= 7 {
                highEnergyTotal += 1
                if log.result == .remembered { highEnergyRemembered += 1 }
            } else {
                lowEnergyTotal += 1
                if log.result == .remembered { lowEnergyRemembered += 1 }
            }
        }

        let hasEnoughData = highEnergyTotal >= 5 && lowEnergyTotal >= 5

        return EnergyRetentionCorrelation(
            highEnergyRetention: highEnergyTotal > 0
                ? Double(highEnergyRemembered) / Double(highEnergyTotal) : 0,
            lowEnergyRetention: lowEnergyTotal > 0
                ? Double(lowEnergyRemembered) / Double(lowEnergyTotal) : 0,
            hasEnoughData: hasEnoughData
        )
    }

    // MARK: - Subscription Trigger Check

    struct TriggerStatus {
        let shouldShowPrompt: Bool
        let reason: String?
    }

    func checkSubscriptionTrigger(
        dailyStatuses: [DailyStatus],
        totalCards: Int,
        weeklyReportViews: Int,
        lastPromptDate: Date?
    ) -> TriggerStatus {
        // 频控：14 天内最多 1 次
        if let lastPrompt = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents(
                [.day], from: lastPrompt, to: Date()
            ).day ?? 0
            if daysSinceLastPrompt < 14 {
                return TriggerStatus(shouldShowPrompt: false, reason: nil)
            }
        }

        // 条件 1：连续 7 天中复习 ≥ 4 天
        let recentStatuses = dailyStatuses
            .filter { $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())! }
        if recentStatuses.count >= 4 {
            return TriggerStatus(shouldShowPrompt: true, reason: "active_user")
        }

        // 条件 2：累计生成卡片 ≥ 40 张
        if totalCards >= 40 {
            return TriggerStatus(shouldShowPrompt: true, reason: "card_milestone")
        }

        // 条件 3：第 3 次查看周报
        if weeklyReportViews >= 3 {
            return TriggerStatus(shouldShowPrompt: true, reason: "report_engagement")
        }

        return TriggerStatus(shouldShowPrompt: false, reason: nil)
    }
}
