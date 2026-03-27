import SwiftUI

struct FloatingInputBar: View {
    let language: AppLanguage
    let fabState: FABState
    let onTypeTap: () -> Void
    let onTapPlanning: () -> Void
    let onTapReview: () -> Void
    let onTapDelete: () -> Void
    let onPressBegan: () -> Void
    let onPressEnded: () -> Void
    let onCancelRecording: () -> Void

    @Namespace private var glassNamespace
    @State private var isTouchDown = false
    @State private var dragOffset: CGSize = .zero
    @State private var didStartRecording = false
    @State private var pressTask: Task<Void, Never>?

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 12) {
                    content
                }
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 28)
        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: isTouchDown)
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: dragOffset)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: fabState)
    }

    private var content: some View {
        ZStack(alignment: .top) {
            if fabState == .recording {
                hintChip
                    .offset(y: -54)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }

            ZStack {
                ambientPulse
                buttonBody
            }
            .frame(width: 132, height: 132)
            .contentShape(Circle())
            .scaleEffect(buttonScale)
            .rotationEffect(.degrees(buttonRotation))
            .offset(dragOffset)
            .gesture(recordingGesture)
        }
    }

    private var hintChip: some View {
        Text(language.ui("松手结束", "Release to finish"))
            .font(.caption.weight(.semibold))
            .foregroundStyle(fabState == .recording ? CalendarTheme.currentTimeRed : CalendarTheme.subtleText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .modifier(GlassCapsuleModifier(tint: fabState == .recording ? CalendarTheme.currentTimeRed.opacity(0.18) : CalendarTheme.accentBlue.opacity(0.14)))
            .modifier(GlassMorphModifier(id: "input_hint", namespace: glassNamespace))
    }

    @ViewBuilder
    private var ambientPulse: some View {
        if fabState == .recording {
            Circle()
                .fill(CalendarTheme.currentTimeRed.opacity(0.14))
                .frame(width: 112, height: 112)
                .scaleEffect(1.02 + min(dragDistance / 420, 0.08))
                .blur(radius: 1.5)

            Circle()
                .fill(CalendarTheme.currentTimeRed.opacity(0.22))
                .frame(width: 94, height: 94)
                .scaleEffect(1 + min(dragDistance / 560, 0.05))
        }
    }

    private var buttonBody: some View {
        ZStack {
            Circle()
                .fill(buttonFill)

            Circle()
                .fill(.white.opacity(fabState == .recording ? 0.18 : 0.14))
                .padding(6)
                .blur(radius: 0.2)

            iconView
        }
        .frame(width: LayoutMetrics.fabSize, height: LayoutMetrics.fabSize)
        .modifier(GlassCircleModifier(tint: glassTint))
        .modifier(GlassMorphModifier(id: "input_button", namespace: glassNamespace))
        .shadow(color: shadowColor, radius: fabState == .recording ? 24 : 16, y: fabState == .recording ? 10 : 8)
        .overlay(alignment: .topLeading) {
            if isTouchDown || fabState == .recording {
                Circle()
                    .fill(.white.opacity(0.28))
                    .frame(width: 16, height: 16)
                    .blur(radius: 1)
                    .offset(x: 14, y: 14)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            if fabState == .processing {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.96)
                    .transition(.scale(scale: 0.86).combined(with: .opacity))
            } else if fabState == .recording {
                Image(systemName: "waveform")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(1.05 + min(dragDistance / 700, 0.08))
                    .symbolEffect(.bounce.byLayer, value: fabState == .recording)
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            } else {
                Image(systemName: "mic.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .scaleEffect(isTouchDown ? 0.94 : 1)
                    .transition(.scale(scale: 0.88).combined(with: .opacity))
            }
        }
        .contentTransition(.symbolEffect(.replace))
    }

    private var buttonFill: some ShapeStyle {
        LinearGradient(
            colors: fabState == .recording
                ? [CalendarTheme.currentTimeRed.opacity(0.94), CalendarTheme.currentTimeRed]
                : [CalendarTheme.accentBlue.opacity(0.94), CalendarTheme.accentBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glassTint: Color {
        fabState == .recording ? CalendarTheme.currentTimeRed.opacity(0.5) : CalendarTheme.accentBlue.opacity(0.42)
    }

    private var shadowColor: Color {
        (fabState == .recording ? CalendarTheme.currentTimeRed : CalendarTheme.accentBlue).opacity(0.22)
    }

    private var dragDistance: CGFloat {
        hypot(dragOffset.width, dragOffset.height)
    }

    private var buttonScale: CGFloat {
        if fabState == .recording {
            return 1.08 + min(dragDistance / 700, 0.04)
        }
        if isTouchDown {
            return 0.95
        }
        return 1
    }

    private var buttonRotation: Double {
        let clamped = max(min(dragOffset.width / 22, 6), -6)
        return Double(clamped)
    }

    private var recordingGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleTouchChanged(value)
            }
            .onEnded { _ in
                handleTouchEnded()
            }
    }

    private func handleTouchChanged(_ value: DragGesture.Value) {
        guard fabState != .processing else { return }

        if !isTouchDown {
            isTouchDown = true
            scheduleRecordingStart()
        }

        if didStartRecording {
            dragOffset = value.translation
        } else if hypot(value.translation.width, value.translation.height) > 12 {
            beginRecordingIfNeeded()
            dragOffset = value.translation
        }
    }

    private func handleTouchEnded() {
        pressTask?.cancel()
        pressTask = nil

        defer {
            isTouchDown = false
            didStartRecording = false
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                dragOffset = .zero
            }
        }

        if didStartRecording || fabState == .recording {
            onPressEnded()
        } else if fabState == .idle {
            onTypeTap()
        } else {
            onCancelRecording()
        }
    }

    private func scheduleRecordingStart() {
        pressTask?.cancel()
        pressTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            beginRecordingIfNeeded()
        }
    }

    @MainActor
    private func beginRecordingIfNeeded() {
        guard isTouchDown, !didStartRecording, fabState == .idle else { return }
        didStartRecording = true
        withAnimation(.spring(response: 0.22, dampingFraction: 0.88)) {
            onPressBegan()
        }
    }
}

private struct GlassCircleModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.tint(tint).interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

private struct GlassCapsuleModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular.tint(tint), in: .capsule)
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

private struct GlassMorphModifier: ViewModifier {
    let id: String
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffectID(id, in: namespace)
        } else {
            content
        }
    }
}

#Preview {
    FloatingInputBar(
        language: .chinese,
        fabState: .idle,
        onTypeTap: {},
        onTapPlanning: {},
        onTapReview: {},
        onTapDelete: {},
        onPressBegan: {},
        onPressEnded: {},
        onCancelRecording: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
