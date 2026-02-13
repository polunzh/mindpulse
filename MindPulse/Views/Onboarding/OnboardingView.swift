import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @State private var showAPIKeyInput = false
    @State private var apiKey = ""

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

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom section
            VStack(spacing: 16) {
                if currentPage == pages.count - 1 {
                    // 最后一页：配置 API Key
                    if showAPIKeyInput {
                        apiKeySection
                    } else {
                        Button {
                            showAPIKeyInput = true
                        } label: {
                            Text("开始使用")
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

                if currentPage < pages.count - 1 {
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

        // 请求通知权限
        Task {
            await NotificationService.shared.requestPermission()
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
