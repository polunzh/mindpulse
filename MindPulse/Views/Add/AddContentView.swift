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

                if viewModel.showPreview {
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

            // URL 抓取失败兜底
            if viewModel.showURLFallback {
                urlFallbackView
            }

            // 错误信息
            if let error = viewModel.errorMessage, !viewModel.showURLFallback {
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

    // MARK: - URL Fallback

    private var urlFallbackView: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.mpSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("网页抓取失败")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.mpBody)
                Text("请尝试手动复制文章正文后粘贴")
                    .font(.caption2)
                    .foregroundColor(.mpCaption)
            }
            Spacer()
            Button("切换粘贴") {
                viewModel.switchToManualPaste()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.mpPrimary)
        }
        .padding(12)
        .background(Color.mpSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
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
