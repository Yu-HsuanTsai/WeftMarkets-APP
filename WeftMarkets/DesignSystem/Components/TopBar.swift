import SwiftUI

/// Figma: System/Top Bar (Default / Searching)
/// Row 1: Weft wordmark, full width. Row 2: search field (left) + 選單 (right);
/// while searching the menu button becomes 取消.
struct WeftTopBar: View {
    @Binding var query: String
    @Binding var isSearching: Bool
    var onMenu: () -> Void
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: WeftSpacing.xxs) {
            WeftWordmark()
                .frame(maxWidth: .infinity)
                .frame(height: 40)

            HStack(spacing: WeftSpacing.sm) {
                searchField
                if isSearching {
                    Button("取消", action: endSearch)
                        .font(.body)
                        .foregroundStyle(WeftColor.accent)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    Button(action: onMenu) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(WeftColor.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("選單")
                    .glassEffect(.regular.interactive(), in: .circle)
                    .overlay(Circle().stroke(WeftColor.ruleFaint, lineWidth: WeftStroke.thin))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, WeftSpacing.md)
        }
        .padding(.bottom, 10)
        .background { TopBarBackdrop() }
        .animation(.snappy(duration: 0.25), value: isSearching)
        .onChange(of: isFieldFocused) { _, focused in
            if focused { isSearching = true }
        }
        .onAppear { if isSearching { isFieldFocused = true } }
    }

    private var searchField: some View {
        HStack(spacing: WeftSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WeftColor.textSecondary)
            TextField(isSearching ? "搜尋 博通 / AVGO" : "搜尋", text: $query)
                .focused($isFieldFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button("清除", systemImage: "xmark.circle.fill") { query = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(WeftColor.textTertiary)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        // Plain (non-interactive) glass: the interactive variant is for buttons
        // and shouldn't sit between the tap and the TextField.
        .glassEffect(.regular, in: .capsule)
        .overlay(Capsule().stroke(WeftColor.ruleFaint, lineWidth: WeftStroke.thin))
        .contentShape(.capsule)
        .onTapGesture { isFieldFocused = true }
    }

    private func endSearch() {
        query = ""
        isFieldFocused = false
        isSearching = false
    }
}

/// White gradient + blur that fades out toward the bottom edge, so content
/// scrolling underneath softens instead of cutting off.
private struct TopBarBackdrop: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(stops: [.init(color: .black, location: 0),
                                           .init(color: .black, location: 0.5),
                                           .init(color: .clear, location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                }
            LinearGradient(stops: [.init(color: WeftColor.bgPrimary.opacity(0.94), location: 0),
                                   .init(color: WeftColor.bgPrimary.opacity(0.82), location: 0.72),
                                   .init(color: WeftColor.bgPrimary.opacity(0), location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea(edges: .top)
    }
}

/// Root of each tab: top bar + content, or search results while searching.
/// The system navigation bar is hidden here only; pushed pages keep theirs.
struct WeftTabRoot<Content: View>: View {
    @State private var query: String
    @State private var isSearching: Bool
    @State private var showsMore = false
    @ViewBuilder var content: Content

    init(initiallySearching: Bool = false, initialQuery: String = "", @ViewBuilder content: () -> Content) {
        _isSearching = State(initialValue: initiallySearching)
        _query = State(initialValue: initialQuery)
        self.content = content()
    }

    var body: some View {
        Group {
            if isSearching {
                SearchView(query: $query)
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(WeftColor.bgPrimary)
        .safeAreaInset(edge: .top, spacing: 0) {
            WeftTopBar(query: $query, isSearching: $isSearching) { showsMore = true }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsMore) {
            MoreSheet().presentationDetents([.large])
        }
    }
}

/// Figma: Nav Bar Large title block, now drawn in content under the top bar.
struct LargeTitleHeader: View {
    let title: String
    var kicker: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let kicker { Kicker(text: kicker) }
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(WeftColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, WeftSpacing.xs)
    }
}

#Preview {
    NavigationStack {
        WeftTabRoot {
            ScrollView {
                LargeTitleHeader(title: "本週", kicker: "WEEKLY EDITION · W41").weftScreen()
            }
        }
    }
    .environment(WatchlistStore())
}
