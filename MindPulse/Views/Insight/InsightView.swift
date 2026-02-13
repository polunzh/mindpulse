import SwiftUI
import SwiftData
import Charts

struct InsightView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InsightViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let stats = viewModel.weeklyStats {
                        weeklyOverview(stats)
                        energyChart(stats)
                        retentionSection
                        topicSection
                        aiInsightsSection
                        subscriptionPromptSection
                    } else {
                        emptyState
                    }
                }
                .padding()
            }
            .background(Color.mpBackground)
            .navigationTitle("洞察")
            .onAppear {
                viewModel.loadData(modelContext: modelContext)
            }
        }
    }

    // MARK: - Weekly Overview

    private func weeklyOverview(_ stats: WeeklyStats) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("本周概览")
                    .font(.headline)
                    .foregroundColor(.mpTitle)
                Spacer()
                Text("\(stats.startDate) - \(stats.endDate)")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
            }

            HStack(spacing: 0) {
                overviewItem(
                    value: "\(stats.totalCardsReviewed)",
                    label: "复习卡片",
                    icon: "rectangle.stack.fill"
                )
                Divider().frame(height: 40)
                overviewItem(
                    value: "\(Int(stats.retentionRate * 100))%",
                    label: "记忆留存",
                    icon: "brain.fill"
                )
                Divider().frame(height: 40)
                overviewItem(
                    value: String(format: "%.1f", stats.averageEnergy),
                    label: "平均能量",
                    icon: "battery.75percent"
                )
                if viewModel.streak > 0 {
                    Divider().frame(height: 40)
                    overviewItem(
                        value: "\(viewModel.streak)",
                        label: "连续天数",
                        icon: "flame.fill"
                    )
                }
            }
        }
        .padding(20)
        .background(Color.mpCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func overviewItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.mpPrimary)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.mpTitle)
            Text(label)
                .font(.caption2)
                .foregroundColor(.mpCaption)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Energy Chart

    private func energyChart(_ stats: WeeklyStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("能量趋势")
                .font(.headline)
                .foregroundColor(.mpTitle)

            Chart(stats.dailyDetails, id: \.date) { detail in
                BarMark(
                    x: .value("日期", detail.date),
                    y: .value("能量", detail.energyLevel ?? 0)
                )
                .foregroundStyle(
                    (detail.energyLevel ?? 0) >= 7
                        ? Color.mpEnergyHigh
                        : (detail.energyLevel ?? 0) >= 4
                            ? Color.mpSecondary
                            : Color.mpEnergyLow
                )
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...10)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 5, 10])
            }
            .frame(height: 160)
        }
        .padding(20)
        .background(Color.mpCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Retention Correlation

    private var retentionSection: some View {
        Group {
            if let cor = viewModel.correlation, cor.hasEnoughData {
                VStack(alignment: .leading, spacing: 12) {
                    Text("能量 & 记忆")
                        .font(.headline)
                        .foregroundColor(.mpTitle)

                    HStack(spacing: 20) {
                        retentionBar(
                            label: "高能量日",
                            subtitle: "能量 ≥ 7",
                            value: cor.highEnergyRetention,
                            color: .mpEnergyHigh
                        )
                        retentionBar(
                            label: "低能量日",
                            subtitle: "能量 < 7",
                            value: cor.lowEnergyRetention,
                            color: .mpEnergyLow
                        )
                    }
                }
                .padding(20)
                .background(Color.mpCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func retentionBar(label: String, subtitle: String, value: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            Text("\(Int(value * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(height: geo.size.height * value)
                    }
            }
            .frame(height: 60)

            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.mpTitle)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.mpCaption)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Topic Distribution

    private var topicSection: some View {
        Group {
            if !viewModel.topicDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("知识领域")
                        .font(.headline)
                        .foregroundColor(.mpTitle)

                    ForEach(viewModel.topicDistribution.prefix(5), id: \.tag) { item in
                        HStack {
                            Text(item.tag)
                                .font(.subheadline)
                                .foregroundColor(.mpBody)
                            Spacer()
                            Text("\(item.count) 张卡片")
                                .font(.caption)
                                .foregroundColor(.mpCaption)
                        }
                    }
                }
                .padding(20)
                .background(Color.mpCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - AI Insights

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 洞察")
                    .font(.headline)
                    .foregroundColor(.mpTitle)
                Spacer()
                if viewModel.aiInsights.isEmpty && !viewModel.isLoadingInsights {
                    Button {
                        Task {
                            await viewModel.loadAIInsights()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("生成洞察")
                        }
                        .font(.caption)
                        .foregroundColor(.mpPrimary)
                    }
                }
            }

            if viewModel.isLoadingInsights {
                HStack {
                    ProgressView()
                    Text("AI 正在分析你的数据...")
                        .font(.caption)
                        .foregroundColor(.mpCaption)
                }
                .padding(.vertical, 8)
            } else if viewModel.aiInsights.isEmpty {
                Text("点击「生成洞察」让 AI 分析你的学习和状态数据")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
            } else {
                ForEach(viewModel.aiInsights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.mpSecondary)
                            .font(.caption)
                            .padding(.top, 2)
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.mpBody)
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.mpForgot)
            }
        }
        .padding(20)
        .background(Color.mpCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Subscription Prompt

    @ViewBuilder
    private var subscriptionPromptSection: some View {
        if viewModel.showSubscriptionPrompt {
            VStack(spacing: 16) {
                Text("想更快把内容变成可复习的行动卡片？")
                    .font(.headline)
                    .foregroundColor(.mpTitle)
                    .multilineTextAlignment(.center)

                Text("如果你愿意，Pro 可以帮你自动优化卡片质量与周报洞察。免费功能仍可继续使用。")
                    .font(.subheadline)
                    .foregroundColor(.mpBody)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    Button {
                        viewModel.recordPromptAction(.dismissed, modelContext: modelContext)
                    } label: {
                        Text("先继续免费使用")
                            .font(.subheadline)
                            .foregroundColor(.mpCaption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mpSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        viewModel.recordPromptAction(.tapped, modelContext: modelContext)
                        // TODO: Navigate to subscription page
                    } label: {
                        Text("了解 Pro")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mpPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                Button {
                    viewModel.recordPromptAction(.notInterested, modelContext: modelContext)
                } label: {
                    Text("不感兴趣，30 天内不再提示")
                        .font(.caption2)
                        .foregroundColor(.mpCaption)
                }
            }
            .padding(20)
            .background(Color.mpCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.mpPrimary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 50))
                .foregroundColor(.mpCaption)

            Text("还没有足够的数据")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.mpTitle)

            Text("完成几次复习后，这里会显示你的学习洞察")
                .font(.subheadline)
                .foregroundColor(.mpCaption)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

#Preview {
    InsightView()
        .modelContainer(for: [
            Card.self, Source.self, ReviewLog.self,
            DailyStatus.self, Subscription.self, PromptLog.self
        ])
}
