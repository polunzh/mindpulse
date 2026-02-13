import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var showAPIKeyInput = false
    @State private var apiKey = ""

    // 示例卡片体验
    @State private var showSampleCards = false
    @State private var sampleIndex = 0
    @State private var sampleFlipped = false

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        (
            "square.and.arrow.down",
            "把你读到的好内容扔进来",
            "粘贴文章链接或文字，什么格式都行"
        ),
        (
            "sparkles",
            "AI 帮你提炼成记忆卡片",
            "自动生成问答卡片，不用自己费心整理"
        ),
        (
            "clock.badge.checkmark",
            "每天 2 分钟，让知识真正留下",
            "科学的间隔重复，碎片时间就够"
        )
    ]

    private let sampleCards: [(question: String, answer: String)] = [
        (
            "为什么「间隔重复」比集中复习更有效？",
            "因为大脑在遗忘边缘重新提取记忆时，会形成更强的神经连接。集中复习产生的是「熟悉感幻觉」，而间隔重复才能产生真正的长期记忆。"
        ),
        (
            "「二八法则」如何应用在个人学习中？",
            "一个领域 80% 的实用价值来自 20% 的核心知识。先识别并掌握这 20% 的关键概念，比试图全面覆盖更高效。"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            if showSampleCards {
                sampleCardExperience
            } else {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }

            // Bottom section
            VStack(spacing: 16) {
                if showSampleCards {
                    // 示例卡片阶段不显示底部按钮（由卡片交互驱动）
                    EmptyView()
                } else if currentPage == pages.count - 1 {
                    if showAPIKeyInput {
                        apiKeySection
                    } else {
                        Button {
                            withAnimation {
                                showSampleCards = true
                            }
                        } label: {
                            Text("先体验一下")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.mpPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                } else {
                    Button {
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        Text("下一步")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.mpPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                if !showSampleCards && currentPage < pages.count - 1 {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("跳过")
                            .font(.subheadline)
                            .foregroundColor(.mpCaption)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.mpBackground)
    }

    // MARK: - Page View

    private func pageView(_ page: (icon: String, title: String, subtitle: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 70))
                .foregroundColor(.mpPrimary)
                .padding(.bottom, 10)

            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.mpTitle)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.body)
                .foregroundColor(.mpCaption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Sample Card Experience

    private var sampleCardExperience: some View {
        VStack(spacing: 20) {
            Text("体验一下")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.mpTitle)
                .padding(.top, 40)

            Text("第 \(sampleIndex + 1)/\(sampleCards.count) 张示例卡片")
                .font(.caption)
                .foregroundColor(.mpCaption)

            Spacer()

            // 示例卡片
            let sample = sampleCards[sampleIndex]
            VStack(spacing: 16) {
                if sampleFlipped {
                    Text(sample.answer)
                        .font(.body)
                        .foregroundColor(.mpBody)
                        .multilineTextAlignment(.center)
                        .padding(24)
                } else {
                    Text(sample.question)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.mpTitle)
                        .multilineTextAlignment(.center)
                        .padding(24)

                    Image(systemName: "hand.tap")
                        .font(.title3)
                        .foregroundColor(.mpCaption.opacity(0.5))
                    Text("点击查看答案")
                        .font(.caption2)
                        .foregroundColor(.mpCaption.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .background(Color.mpCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
            .padding(.horizontal, 24)
            .onTapGesture {
                if !sampleFlipped {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        sampleFlipped = true
                    }
                }
            }

            Spacer()

            if sampleFlipped {
                Button {
                    withAnimation {
                        if sampleIndex + 1 < sampleCards.count {
                            sampleIndex += 1
                            sampleFlipped = false
                        } else {
                            // 示例完成，进入 API Key 配置
                            showSampleCards = false
                            showAPIKeyInput = true
                            currentPage = pages.count - 1
                        }
                    }
                } label: {
                    Text(sampleIndex + 1 < sampleCards.count ? "下一张" : "开始使用")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.mpPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
            }

            Button {
                showSampleCards = false
                showAPIKeyInput = true
                currentPage = pages.count - 1
            } label: {
                Text("跳过体验")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        VStack(spacing: 12) {
            Text("配置 Claude API Key")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.mpTitle)

            Text("用于 AI 生成卡片，你的数据不会存储在服务器")
                .font(.caption)
                .foregroundColor(.mpCaption)

            SecureField("sk-ant-...", text: $apiKey)
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .background(Color.mpSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Button {
                    completeOnboarding()
                } label: {
                    Text("稍后配置")
                        .font(.subheadline)
                        .foregroundColor(.mpCaption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.mpSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    if !apiKey.isEmpty {
                        UserDefaults.standard.set(apiKey, forKey: AIService.apiKeyKey)
                    }
                    completeOnboarding()
                } label: {
                    Text("完成")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(!apiKey.isEmpty ? Color.mpPrimary : Color.mpCaption)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
        isOnboardingComplete = true

        Task {
            await NotificationService.shared.requestPermission()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
