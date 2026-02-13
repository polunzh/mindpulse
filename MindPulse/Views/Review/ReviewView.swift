import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReviewViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mpBackground.ignoresSafeArea()

                if viewModel.todayCards.isEmpty {
                    emptyState
                } else if viewModel.isCompleted {
                    completedState
                } else {
                    reviewContent
                }

                // 撤回状态记录的 Banner
                if viewModel.showUndoBanner {
                    VStack {
                        Spacer()
                        undoBanner
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("复习")
            .sheet(isPresented: $viewModel.showStatusRecord) {
                StatusRecordView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadTodayCards(modelContext: modelContext)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.mpCaption)

            Text("还没有卡片")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.mpTitle)

            Text("去「添加」页面导入一篇文章\nAI 会帮你生成复习卡片")
                .font(.body)
                .foregroundColor(.mpCaption)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Review Content

    private var reviewContent: some View {
        VStack(spacing: 24) {
            // 进度
            HStack {
                Text("\(viewModel.reviewedCount)/\(viewModel.todayCards.count) 张")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
                Spacer()
            }
            .padding(.horizontal)

            ProgressView(value: viewModel.progress)
                .tint(.mpPrimary)
                .padding(.horizontal)

            Spacer()

            // 卡片
            if let card = viewModel.currentCard {
                CardView(
                    card: card,
                    isFlipped: viewModel.isFlipped,
                    dragOffset: viewModel.dragOffset,
                    onTap: { viewModel.flipCard() },
                    onSwipeLeft: { viewModel.swipeCard(result: .forgot) },
                    onSwipeRight: { viewModel.swipeCard(result: .remembered) }
                )
                .padding(.horizontal)
            }

            Spacer()

            // 底部提示
            if viewModel.isFlipped {
                HStack(spacing: 40) {
                    swipeHint(text: "忘了", icon: "arrow.left", color: .mpForgot)
                    swipeHint(text: "记得", icon: "arrow.right", color: .mpRemembered)
                }
                .padding(.bottom, 20)
            } else {
                Text("点击卡片查看答案")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Completed State

    private var completedState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.mpRemembered)

            Text("今日复习完成")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.mpTitle)

            HStack(spacing: 30) {
                statItem(
                    value: "\(viewModel.reviewedCount)",
                    label: "已复习"
                )
                statItem(
                    value: "\(Int(viewModel.retentionRate * 100))%",
                    label: "记住率"
                )
            }
        }
        .padding()
    }

    // MARK: - Components

    private func swipeHint(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.subheadline)
        .foregroundColor(color)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.mpTitle)
            Text(label)
                .font(.caption)
                .foregroundColor(.mpCaption)
        }
    }

    private var undoBanner: some View {
        HStack {
            Text("状态已记录")
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Button("撤回") {
                viewModel.undoStatus()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.mpTitle.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    ReviewView()
        .modelContainer(for: [Card.self, Source.self, ReviewLog.self, DailyStatus.self])
}
