import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage(AIService.apiKeyKey) private var apiKey = ""
    @AppStorage("reminder_hour") private var reminderHour = 9
    @AppStorage("reminder_enabled") private var reminderEnabled = true
    @AppStorage("notification_muted_until") private var mutedUntilTimestamp: Double = 0

    @State private var showAPIKey = false
    @State private var tempAPIKey = ""

    private var isMuted: Bool {
        mutedUntilTimestamp > Date().timeIntervalSince1970
    }

    var body: some View {
        List {
            // API 配置
            Section {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.mpPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Claude API Key")
                            .font(.subheadline)
                        if apiKey.isEmpty {
                            Text("未配置")
                                .font(.caption)
                                .foregroundColor(.mpForgot)
                        } else {
                            Text(maskedKey)
                                .font(.caption)
                                .foregroundColor(.mpCaption)
                        }
                    }
                    Spacer()
                    Button(apiKey.isEmpty ? "配置" : "修改") {
                        tempAPIKey = apiKey
                        showAPIKey = true
                    }
                    .font(.caption)
                    .foregroundColor(.mpPrimary)
                }
            } header: {
                Text("AI 服务")
            } footer: {
                Text("API Key 仅存储在本地设备，不会上传到任何服务器。")
            }

            // 通知设置
            Section {
                Toggle(isOn: $reminderEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.mpSecondary)
                        Text("每日复习提醒")
                    }
                }
                .onChange(of: reminderEnabled) { _, newValue in
                    if newValue {
                        NotificationService.shared.scheduleDailyReminder(
                            at: reminderHour,
                            cardCount: 5
                        )
                    } else {
                        NotificationService.shared.cancelReminder()
                    }
                }

                if reminderEnabled {
                    Picker("提醒时间", selection: $reminderHour) {
                        ForEach(6..<23) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                    .onChange(of: reminderHour) { _, newValue in
                        NotificationService.shared.scheduleDailyReminder(
                            at: newValue,
                            cardCount: 5
                        )
                    }
                }

                if !isMuted {
                    Button {
                        // 静音 7 天
                        let muteUntil = Date().addingTimeInterval(7 * 86400)
                        mutedUntilTimestamp = muteUntil.timeIntervalSince1970
                        NotificationService.shared.cancelAll()
                    } label: {
                        HStack {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.mpCaption)
                            Text("静音 7 天")
                                .foregroundColor(.mpBody)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.mpCaption)
                        Text("通知已静音")
                            .foregroundColor(.mpCaption)
                        Spacer()
                        Button("取消静音") {
                            mutedUntilTimestamp = 0
                            if reminderEnabled {
                                NotificationService.shared.scheduleDailyReminder(
                                    at: reminderHour,
                                    cardCount: 5
                                )
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.mpPrimary)
                    }
                }
            } header: {
                Text("通知")
            } footer: {
                Text("每天最多 1 条提醒，不会打扰你。")
            }

            // 数据管理
            Section {
                NavigationLink {
                    SourceListView()
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.mpPrimary)
                        Text("内容管理")
                    }
                }

                NavigationLink {
                    CardListView()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.stack")
                            .foregroundColor(.mpPrimary)
                        Text("卡片管理")
                    }
                }
            } header: {
                Text("数据")
            }

            // 隐私
            Section {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.mpRemembered)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("数据隐私")
                            .font(.subheadline)
                        Text("所有数据存储在本地。仅生成卡片和洞察时会将内容摘要发送给 Claude AI 服务。")
                            .font(.caption)
                            .foregroundColor(.mpCaption)
                    }
                }
            } header: {
                Text("隐私")
            }

            // 关于
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.mpCaption)
                }
            } header: {
                Text("关于")
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAPIKey) {
            apiKeySheet
        }
    }

    // MARK: - Masked Key

    private var maskedKey: String {
        guard apiKey.count > 10 else { return "••••••••" }
        let prefix = String(apiKey.prefix(7))
        let suffix = String(apiKey.suffix(4))
        return "\(prefix)•••\(suffix)"
    }

    // MARK: - API Key Sheet

    private var apiKeySheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("输入你的 Claude API Key")
                    .font(.headline)
                    .foregroundColor(.mpTitle)

                Text("可以在 console.anthropic.com 获取")
                    .font(.caption)
                    .foregroundColor(.mpCaption)

                SecureField("sk-ant-...", text: $tempAPIKey)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color.mpSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    apiKey = tempAPIKey
                    showAPIKey = false
                } label: {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(!tempAPIKey.isEmpty ? Color.mpPrimary : Color.mpCaption)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(tempAPIKey.isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showAPIKey = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Source List View

struct SourceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Source.createdAt, order: .reverse) private var sources: [Source]

    var body: some View {
        List {
            if sources.isEmpty {
                Text("还没有添加任何内容")
                    .foregroundColor(.mpCaption)
            } else {
                ForEach(sources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.title ?? "未命名")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.mpTitle)

                        if let domain = source.domain {
                            Text(domain)
                                .font(.caption)
                                .foregroundColor(.mpPrimary)
                        }

                        Text("\(source.cards.count) 张卡片")
                            .font(.caption)
                            .foregroundColor(.mpCaption)

                        Text(source.createdAt.fullDateString)
                            .font(.caption2)
                            .foregroundColor(.mpCaption)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(sources[index])
                    }
                    try? modelContext.save()
                }
            }
        }
        .navigationTitle("内容管理")
    }
}

// MARK: - Card List View

struct CardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.createdAt, order: .reverse) private var cards: [Card]

    var body: some View {
        List {
            if cards.isEmpty {
                Text("还没有生成任何卡片")
                    .foregroundColor(.mpCaption)
            } else {
                ForEach(cards) { card in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(card.question)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.mpTitle)
                                .lineLimit(2)
                            Spacer()
                            if !card.isActive {
                                Text("已归档")
                                    .font(.caption2)
                                    .foregroundColor(.mpCaption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.mpSurface)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(card.answer)
                            .font(.caption)
                            .foregroundColor(.mpBody)
                            .lineLimit(2)

                        HStack {
                            Text("复习 \(card.repetition) 次")
                            Text("·")
                            Text("难度 \(String(format: "%.1f", card.easeFactor))")
                        }
                        .font(.caption2)
                        .foregroundColor(.mpCaption)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing) {
                        Button {
                            card.isActive.toggle()
                            try? modelContext.save()
                        } label: {
                            Text(card.isActive ? "归档" : "恢复")
                        }
                        .tint(card.isActive ? .mpSecondary : .mpPrimary)

                        Button(role: .destructive) {
                            modelContext.delete(card)
                            try? modelContext.save()
                        } label: {
                            Text("删除")
                        }
                    }
                }
            }
        }
        .navigationTitle("卡片管理")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
