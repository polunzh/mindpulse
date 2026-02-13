import Foundation
import SwiftData
import SwiftUI

@Observable
final class InsightViewModel {
    var weeklyStats: WeeklyStats?
    var aiInsights: [String] = []
    var isLoadingInsights: Bool = false
    var streak: Int = 0
    var topicDistribution: [(tag: String, count: Int)] = []
    var correlation: StatsEngine.EnergyRetentionCorrelation?
    var errorMessage: String?

    // Subscription prompt
    var showSubscriptionPrompt: Bool = false
    var weeklyReportViews: Int {
        get { UserDefaults.standard.integer(forKey: "weekly_report_views") }
        set { UserDefaults.standard.set(newValue, forKey: "weekly_report_views") }
    }

    private let statsEngine = StatsEngine()
    private let aiService = AIService()

    // MARK: - Load Data

    func loadData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 本周的起始日（周一）
        let weekday = calendar.component(.weekday, from: today)
        let daysToMonday = (weekday + 5) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysToMonday, to: today)!
        let weekEnd = today

        do {
            // 获取本周复习日志
            let logDescriptor = FetchDescriptor<ReviewLog>(
                predicate: #Predicate<ReviewLog> { log in
                    log.reviewedAt >= weekStart
                }
            )
            let logs = try modelContext.fetch(logDescriptor)

            // 获取所有状态记录
            let statusDescriptor = FetchDescriptor<DailyStatus>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let allStatuses = try modelContext.fetch(statusDescriptor)

            let weekStatuses = allStatuses.filter { $0.date >= weekStart }

            // 生成周报
            weeklyStats = statsEngine.generateWeeklyStats(
                reviewLogs: logs,
                dailyStatuses: weekStatuses,
                from: weekStart,
                to: weekEnd
            )

            // 连续天数
            streak = statsEngine.currentStreak(from: allStatuses)

            // 主题分布
            let sourceDescriptor = FetchDescriptor<Source>()
            let sources = try modelContext.fetch(sourceDescriptor)
            topicDistribution = statsEngine.topicDistribution(from: sources)

            // 能量-留存率关联
            let allLogsDescriptor = FetchDescriptor<ReviewLog>()
            let allLogs = try modelContext.fetch(allLogsDescriptor)
            correlation = statsEngine.energyRetentionCorrelation(
                reviewLogs: allLogs,
                dailyStatuses: allStatuses
            )

            // 记录查看次数
            weeklyReportViews += 1

            // 检查是否需要显示订阅提示
            checkSubscriptionTrigger(
                modelContext: modelContext,
                dailyStatuses: allStatuses
            )

        } catch {
            errorMessage = "加载数据失败"
        }
    }

    // MARK: - AI Insights

    func loadAIInsights() async {
        guard let stats = weeklyStats else { return }

        isLoadingInsights = true
        do {
            let insights = try await aiService.generateInsights(from: stats)
            await MainActor.run {
                aiInsights = insights
                isLoadingInsights = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoadingInsights = false
            }
        }
    }

    // MARK: - Subscription Check

    private func checkSubscriptionTrigger(modelContext: ModelContext, dailyStatuses: [DailyStatus]) {
        // 检查订阅状态
        let subDescriptor = FetchDescriptor<Subscription>()
        guard let subscription = try? modelContext.fetch(subDescriptor).first else { return }
        guard subscription.status == .free else { return }

        // 检查上次提示时间
        let subscriptionType = PromptType.subscription
        let promptDescriptor = FetchDescriptor<PromptLog>(
            predicate: #Predicate<PromptLog> { $0.type == subscriptionType },
            sortBy: [SortDescriptor(\.shownAt, order: .reverse)]
        )

        let lastPrompt = try? modelContext.fetch(promptDescriptor).first

        // 检查"不感兴趣"标记
        if let last = lastPrompt, last.action == .notInterested {
            let daysSince = Calendar.current.dateComponents(
                [.day], from: last.shownAt, to: Date()
            ).day ?? 0
            if daysSince < 30 { return }
        }

        // 获取总卡片数
        let cardDescriptor = FetchDescriptor<Card>()
        let totalCards = (try? modelContext.fetch(cardDescriptor).count) ?? 0

        let trigger = statsEngine.checkSubscriptionTrigger(
            dailyStatuses: dailyStatuses,
            totalCards: totalCards,
            weeklyReportViews: weeklyReportViews,
            lastPromptDate: lastPrompt?.shownAt
        )

        showSubscriptionPrompt = trigger.shouldShowPrompt
    }

    // MARK: - Subscription Actions

    func recordPromptAction(_ action: UserAction, modelContext: ModelContext) {
        let log = PromptLog(type: .subscription, action: action)
        modelContext.insert(log)
        try? modelContext.save()
        showSubscriptionPrompt = false
    }
}
