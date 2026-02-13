import SwiftUI

struct CardView: View {
    let card: Card
    let isFlipped: Bool
    let dragOffset: CGSize
    let onTap: () -> Void
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        ZStack {
            if isFlipped {
                backSide
            } else {
                frontSide
            }
        }
        .frame(maxWidth: .infinity, minHeight: 380)
        .background(Color.mpCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 15, y: 5)
        .rotation3DEffect(
            .degrees(isFlipped ? 0 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .offset(x: offset.width)
        .rotationEffect(.degrees(Double(offset.width / 30)))
        .opacity(1.0 - abs(Double(offset.width)) / 300.0)
        .gesture(
            isFlipped ? dragGesture : nil
        )
        .onTapGesture {
            if !isFlipped {
                onTap()
            }
        }
        .overlay(alignment: .top) {
            swipeIndicator
        }
        .animation(.spring(response: 0.4), value: offset)
        .animation(.easeInOut(duration: 0.4), value: isFlipped)
    }

    // MARK: - Front Side (Question)

    private var frontSide: some View {
        VStack(spacing: 16) {
            if let source = card.source, !source.tags.isEmpty {
                HStack {
                    Text(source.tags.first ?? "")
                        .font(.caption)
                        .foregroundColor(.mpPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.mpPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    Spacer()
                }
            }

            Spacer()

            Text(card.question)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.mpTitle)
                .multilineTextAlignment(.center)

            Spacer()

            Image(systemName: "hand.tap")
                .font(.title3)
                .foregroundColor(.mpCaption.opacity(0.5))

            Text("点击翻转")
                .font(.caption2)
                .foregroundColor(.mpCaption.opacity(0.5))
        }
        .padding(24)
    }

    // MARK: - Back Side (Answer)

    private var backSide: some View {
        VStack(spacing: 16) {
            if let source = card.source, !source.tags.isEmpty {
                HStack {
                    Text(source.tags.first ?? "")
                        .font(.caption)
                        .foregroundColor(.mpPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.mpPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    Spacer()
                }
            }

            Spacer()

            Text(card.answer)
                .font(.body)
                .foregroundColor(.mpBody)
                .multilineTextAlignment(.center)

            if !card.sourceQuote.isEmpty {
                Divider()
                    .padding(.horizontal, 20)

                Text("「\(card.sourceQuote)」")
                    .font(.caption)
                    .foregroundColor(.mpCaption)
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            Spacer()

            Text("← 忘了 | 记得 →")
                .font(.caption)
                .foregroundColor(.mpCaption.opacity(0.6))
        }
        .padding(24)
    }

    // MARK: - Swipe Indicator

    @ViewBuilder
    private var swipeIndicator: some View {
        if offset.width > 30 {
            Text("记得")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.mpRemembered)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mpRemembered, lineWidth: 2)
                )
                .rotationEffect(.degrees(-15))
                .padding(.top, 20)
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if offset.width < -30 {
            Text("忘了")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.mpForgot)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.mpForgot, lineWidth: 2)
                )
                .rotationEffect(.degrees(15))
                .padding(.top, 20)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: 500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        offset = .zero
                        onSwipeRight()
                    }
                } else if value.translation.width < -swipeThreshold {
                    withAnimation(.easeOut(duration: 0.3)) {
                        offset = CGSize(width: -500, height: 0)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        offset = .zero
                        onSwipeLeft()
                    }
                } else {
                    withAnimation(.spring()) {
                        offset = .zero
                    }
                }
            }
    }
}

#Preview {
    let card = Card(
        question: "为什么说「复利效应」在知识积累中比在财务上更强大？",
        answer: "因为知识的复利没有边际递减效应。你学到的每一个新概念都能与已有知识产生组合，可能性呈指数增长。",
        sourceQuote: "知识是唯一不会因分享而减少的资产"
    )
    CardView(
        card: card,
        isFlipped: false,
        dragOffset: .zero,
        onTap: {},
        onSwipeLeft: {},
        onSwipeRight: {}
    )
    .padding()
}
