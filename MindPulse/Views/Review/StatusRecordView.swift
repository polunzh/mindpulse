import SwiftUI

struct StatusRecordView: View {
    @Bindable var viewModel: ReviewViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // 复习结果
                VStack(spacing: 8) {
                    Text("今天复习了 \(viewModel.reviewedCount) 张")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.mpTitle)

                    Text("记住了 \(viewModel.rememberedCount) 张 (\(Int(viewModel.retentionRate * 100))%)")
                        .font(.subheadline)
                        .foregroundColor(.mpCaption)
                }
                .padding(.top, 20)

                Divider()
                    .padding(.horizontal, 40)

                // 能量滑块
                VStack(spacing: 16) {
                    Text("今日状态")
                        .font(.headline)
                        .foregroundColor(.mpTitle)

                    HStack(spacing: 12) {
                        Image(systemName: "battery.0percent")
                            .foregroundColor(.mpEnergyLow)
                        Slider(value: $viewModel.energyLevel, in: 0...10, step: 1)
                            .tint(energyColor)
                        Image(systemName: "battery.100percent")
                            .foregroundColor(.mpEnergyHigh)
                    }
                    .padding(.horizontal)

                    Text("能量值: \(Int(viewModel.energyLevel))/10")
                        .font(.caption)
                        .foregroundColor(.mpCaption)
                }

                // 快捷标签
                VStack(spacing: 12) {
                    Text("关键词 (可选)")
                        .font(.subheadline)
                        .foregroundColor(.mpCaption)

                    FlowLayout(spacing: 8) {
                        ForEach(ReviewViewModel.quickTags, id: \.self) { tag in
                            Button {
                                if viewModel.statusKeyword == tag {
                                    viewModel.statusKeyword = ""
                                } else {
                                    viewModel.statusKeyword = tag
                                }
                            } label: {
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.statusKeyword == tag
                                            ? Color.mpPrimary
                                            : Color.mpSurface
                                    )
                                    .foregroundColor(
                                        viewModel.statusKeyword == tag
                                            ? .white
                                            : .mpBody
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // 自定义输入
                    TextField("或输入自定义关键词...", text: $viewModel.statusKeyword)
                        .font(.subheadline)
                        .padding(12)
                        .background(Color.mpSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }

                Spacer()

                // 操作按钮
                VStack(spacing: 12) {
                    Button {
                        viewModel.saveStatus()
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.mpPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        viewModel.skipStatus()
                        dismiss()
                    } label: {
                        Text("跳过")
                            .font(.subheadline)
                            .foregroundColor(.mpCaption)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.mpBackground)
            .navigationTitle("记录状态")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var energyColor: Color {
        if viewModel.energyLevel >= 7 {
            return .mpEnergyHigh
        } else if viewModel.energyLevel >= 4 {
            return .mpSecondary
        } else {
            return .mpEnergyLow
        }
    }
}

// MARK: - Flow Layout for tags

struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
