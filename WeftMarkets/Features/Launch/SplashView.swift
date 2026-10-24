import SwiftUI

/// Figma: 00b 載入中 — shown over the app until the first weekly summary loads.
/// (00a, the static launch screen, is the system's generated white launch screen.)
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            WeftColor.bgPrimary.ignoresSafeArea()
            VStack(spacing: WeftSpacing.md) {
                WeftWordmark(size: 56)
                VStack(spacing: WeftSpacing.lg) {
                    Text("所有財經節目，一週重點滑著看完。")
                        .font(.subheadline)
                        .foregroundStyle(WeftColor.textSecondary)
                        .multilineTextAlignment(.center)
                    progressBar
                }
            }
            .padding(.horizontal, WeftSpacing.xl)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weft，正在載入")
        .onAppear { isAnimating = true }
    }

    /// Indeterminate bar: a 64pt accent segment sliding across a 160pt track.
    private var progressBar: some View {
        Rectangle()
            .fill(WeftColor.skeleton)
            .frame(width: 160, height: 4)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(WeftColor.accent)
                    .frame(width: 64, height: 4)
                    .offset(x: isAnimating && !reduceMotion ? 96 : 0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                               value: isAnimating)
            }
            .clipped()
    }
}

#Preview {
    SplashView()
}
