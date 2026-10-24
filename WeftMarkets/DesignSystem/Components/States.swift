import SwiftUI

// Figma: State/State View (Loading / Empty / Error)
struct StateView: View {
    enum Kind { case loading, empty, error }
    let kind: Kind
    let title: String
    var message: String = ""
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: WeftSpacing.sm) {
            switch kind {
            case .loading:
                ProgressView().controlSize(.large).tint(WeftColor.textPrimary)
            case .empty:
                Image(systemName: "tray").font(.system(size: 36, weight: .light))
            case .error:
                Image(systemName: "exclamationmark.triangle").font(.system(size: 36, weight: .light))
            }
            Text(title).font(.headline).multilineTextAlignment(.center)
            if !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(WeftColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(WeftButtonStyle(kind: kind == .error ? .primary : .secondary))
                    .fixedSize()
                    .padding(.top, WeftSpacing.xs)
            }
        }
        .padding(.horizontal, WeftSpacing.lg)
        .padding(.vertical, WeftSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// Figma: State/Skeleton Row
struct SkeletonRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.xs) {
            bone(width: 140, height: 12)
            bone(width: 300, height: 18)
            bone(width: nil, height: 12)
            bone(width: 240, height: 12)
        }
        .padding(.vertical, WeftSpacing.md)
        .weftBottomHairline()
        .accessibilityHidden(true)
    }

    private func bone(width: CGFloat?, height: CGFloat) -> some View {
        Rectangle()
            .fill(WeftColor.skeleton)
            .frame(maxWidth: width ?? .infinity, alignment: .leading)
            .frame(width: width, height: height)
    }
}

/// Loads a value from the repository and renders Loading / Error / content.
/// Pull to refresh and retry re-run the same loader.
struct AsyncContent<Value, Content: View, Placeholder: View>: View {
    let load: () async throws -> Value
    @ViewBuilder var content: (Value) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var state: LoadState<Value> = .loading

    init(load: @escaping () async throws -> Value,
         @ViewBuilder content: @escaping (Value) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.load = load
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                placeholder()
            case .failed(let error):
                StateView(kind: .error, title: "讀不到資料",
                          message: error.localizedDescription,
                          actionTitle: "重試") { Task { await reload() } }
            case .loaded(let value):
                content(value)
            }
        }
        .task { if state.value == nil { await reload() } }
        .refreshable { await reload(showsPlaceholder: false) }
    }

    private func reload(showsPlaceholder: Bool = true) async {
        if showsPlaceholder { state = .loading }
        do {
            state = .loaded(try await load())
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error)
        }
    }
}

extension AsyncContent where Placeholder == StateView {
    init(loadingTitle: String,
         load: @escaping () async throws -> Value,
         @ViewBuilder content: @escaping (Value) -> Content) {
        self.init(load: load, content: content) {
            StateView(kind: .loading, title: loadingTitle, message: "資料每日 11:30（台北）更新")
        }
    }
}
