import SwiftUI
import SwiftData

struct AddContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AddContentViewModel()
    @State private var showClipboardAlert = false
    @State private var clipboardContent: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mpBackground.ignoresSafeArea()

                if viewModel.showManualCardCreation {
                    manualCardContent
                } else if viewModel.showPreview {
                    cardPreviewContent
                } else {
                    inputContent
                }
            }
            .navigationTitle("添加内容")
            .onAppear {
                viewModel.setup(modelContext: modelContext)
                checkClipboard()
            }
            .alert("检测到剪贴板内容", isPresented: $showClipboardAlert) {
                Button("使用") {
                    if let content = clipboardContent {
                        viewModel.useClipboardContent(content)
                    }
                }
                Button("忽略", role: .cancel) {}
            } message: {
                if let content = clipboardContent {
                    let preview = String(content.prefix(80))
                    Text(preview + (content.count > 80 ? "..." : ""))
                }
            }
        }
    }

    // MARK: - Input Content

    private var inputContent: some View {
        VStack(spacing: 20) {
            if !viewModel.hasAPIKey {
                apiKeyWarning
            }

            // 输入区域
            VStack(alignment: .leading, spacing: 8) {
                Text("粘贴文章内容或 URL")
                    .font(.subheadline)
                    .foregroundColor(.mpCaption)

                TextEditor(text: $viewModel.inputText)
                    .font(.body)
                    .foregroundColor(.mpBody)
                    .frame(minHeight: 200)
                    .padding(12)
                    .background(Color.mpCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mpSurface, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if viewModel.inputText.isEmpty {
                            Text("粘贴一篇文章、一段笔记，或一个网页链接...")
                                .font(.body)
                                .foregroundColor(.mpCaption.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .padding(.horizontal)

            // 失败态处理
            if let failure = viewModel.failureType {
                failureView(type: failure)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.mpForgot)
                    .padding(.horizontal)
            }

            Spacer()

            // 生成按钮
            Button {
                Task {
                    await viewModel.generateCards()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.isLoading ? "AI 正在生成卡片..." : "生成卡片")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    viewModel.isInputValid && !viewModel.isLoading
                        ? Color.mpPrimary
                        : Color.mpCaption
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.isInputValid || viewModel.isLoading)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
    }

    // MARK: - Card Preview

    private var cardPreviewContent: some View {
        VStack(spacing: 16) {
            Text("AI 生成了 \(viewModel.generatedCards.count) 张卡片")
                .font(.headline)
                .foregroundColor(.mpTitle)
                .padding(.top)

            Text("取消选择你不想要的卡片")
                .font(.caption)
                .foregroundColor(.mpCaption)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.generatedCards.enumerated()), id: \.element.id) { index, card in
                        CardPreviewItem(card: card) {
                            viewModel.toggleCard(at: index)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // 操作按钮
            HStack(spacing: 12) {
                Button {
                    viewModel.reset()
                } label: {
                    Text("重新输入")
                        .font(.subheadline)
                        .foregroundColor(.mpCaption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.mpSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.saveSelectedCards()
                } label: {
                    let count = viewModel.generatedCards.filter(\.isSelected).count
                    Text("保存 \(count) 张卡片")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(count > 0 ? Color.mpPrimary : Color.mpCaption)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.generatedCards.filter(\.isSelected).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - API Key Warning

    private var apiKeyWarning: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.mpSecondary)
            Text("请先在设置中配置 Claude API Key")
                .font(.caption)
                .foregroundColor(.mpBody)
            Spacer()
            NavigationLink {
                SettingsView()
            } label: {
                Text("去设置")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.mpPrimary)
            }
        }
        .padding(12)
        .background(Color.mpSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    // MARK: - Failure Views

    private func failureView(type: AddContentFailureType) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.mpSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(failureTitle(type))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.mpBody)
                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .font(.caption2)
                            .foregroundColor(.mpCaption)
                    }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                // 重试按钮（所有失败态都有）
                Button {
                    Task { await viewModel.retry() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("重试")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.mpPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.mpPrimary.opacity(0.1))
                    .clipShape(Capsule())
                }

                // 按失败类型显示不同的降级按钮
                switch type {
                case .urlFetch:
                    Button {
                        viewModel.switchToManualPaste()
                    } label: {
                        Text("改为手动粘贴")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.mpSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.mpSecondary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                case .aiTimeout:
                    Button {
                        viewModel.saveToDraft()
                    } label: {
                        Text("稍后处理")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.mpCaption)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.mpSurface)
                            .clipShape(Capsule())
                    }

                case .aiParseFailed:
                    Button {
                        viewModel.switchToManualCardCreation()
                    } label: {
                        Text("手动建卡")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.mpSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.mpSecondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }
        }
        .padding(12)
        .background(Color.mpSecondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }

    private func failureTitle(_ type: AddContentFailureType) -> String {
        switch type {
        case .urlFetch: return "网页抓取失败"
        case .aiTimeout: return "AI 请求失败"
        case .aiParseFailed: return "AI 返回格式异常"
        }
    }

    // MARK: - Manual Card Creation

    private var manualCardContent: some View {
        VStack(spacing: 20) {
            Text("手动创建卡片")
                .font(.headline)
                .foregroundColor(.mpTitle)
                .padding(.top)

            VStack(alignment: .leading, spacing: 8) {
                Text("问题（正面）")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
                TextEditor(text: $viewModel.manualQuestion)
                    .font(.body)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color.mpCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.mpSurface, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("答案（背面）")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
                TextEditor(text: $viewModel.manualAnswer)
                    .font(.body)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color.mpCard)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.mpSurface, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.mpForgot)
                    .padding(.horizontal)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    viewModel.showManualCardCreation = false
                } label: {
                    Text("返回")
                        .font(.subheadline)
                        .foregroundColor(.mpCaption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.mpSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.saveManualCard()
                } label: {
                    Text("保存卡片")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            !viewModel.manualQuestion.isEmpty && !viewModel.manualAnswer.isEmpty
                                ? Color.mpPrimary
                                : Color.mpCaption
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.manualQuestion.isEmpty || viewModel.manualAnswer.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Clipboard

    private func checkClipboard() {
        if let content = viewModel.checkClipboard() {
            clipboardContent = content
            showClipboardAlert = true
        }
    }
}

// MARK: - Card Preview Item

struct CardPreviewItem: View {
    let card: AddContentViewModel.PreviewCard
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: card.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(card.isSelected ? .mpPrimary : .mpCaption)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 8) {
                    Text(card.question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.mpTitle)
                        .multilineTextAlignment(.leading)

                    Text(card.answer)
                        .font(.caption)
                        .foregroundColor(.mpBody)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Spacer()
            }
            .padding(16)
            .background(Color.mpCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        card.isSelected ? Color.mpPrimary.opacity(0.3) : Color.mpSurface,
                        lineWidth: 1
                    )
            )
        }
    }
}

#Preview {
    AddContentView()
        .modelContainer(for: [Card.self, Source.self])
}
