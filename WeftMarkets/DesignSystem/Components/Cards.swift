import SwiftUI

// Figma: Content/Episode Card
struct EpisodeCard: View {
    let episode: Episode
    var showsThisWeekBadge = true
    var isRead = false
    /// Override the card body with a single note (追蹤 / 搜尋 results).
    var note: Note?

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.xs) {
            HStack(spacing: WeftSpacing.xs) {
                Text("\(episode.showName) · \(episode.date)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)
                Spacer()
                if showsThisWeekBadge { TickerTag(text: "本週") }
            }
            Text(note?.title ?? episode.title)
                .font(.headline)
                .lineLimit(2)
            Text(note?.event ?? episode.summary)
                .font(.footnote)
                .foregroundStyle(WeftColor.textSecondary)
                .lineLimit(3)
            let tickers = note?.tickers ?? episode.tickers
            if !tickers.isEmpty { TickerTagRow(tickers: tickers) }
            HStack {
                Text(meta)
                    .font(.weftMono)
                    .foregroundStyle(WeftColor.textSecondary)
                Spacer()
                if isRead {
                    Label("已讀", systemImage: "checkmark")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WeftColor.accent)
                }
            }
        }
        .padding(.vertical, WeftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .weftBottomHairline()
        .contentShape(Rectangle())
    }

    private var meta: String {
        if let note { return "\(episode.title.prefix(14)) · \(note.timeLabel)" }
        return "\(episode.noteCount) 則重點 · \(episode.estimatedTokens.formatted()) tokens（估算）"
    }
}

// Figma: Content/Note Card (重點卡)
struct NoteCard: View {
    let episode: Episode
    let note: Note
    var kicker: String?
    @State private var showsExtraction = false
    @State private var showsTranscript = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.sm) {
            HStack {
                Kicker(text: kicker ?? "重點 \(note.index) / \(episode.noteCount)")
                Spacer()
                Button {
                    if let url = episode.sourceURL(atMinute: note.startMinute) { openURL(url) }
                } label: {
                    Label(note.timeLabel, systemImage: "play.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WeftColor.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().stroke(WeftColor.accent, lineWidth: WeftStroke.thin))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("從 \(note.timeLabel) 開始播放原始節目")
            }
            Text(note.title).font(.title3.weight(.medium))
            block("事件", note.event)
            block("觀點", note.view)
            if let risk = note.risk {
                block("風險", risk)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(WeftColor.highlightSoft)
            }
            if !note.tickers.isEmpty { TickerTagRow(tickers: note.tickers, limit: 4) }
            if showsTranscript {
                TranscriptEvidenceView(episodeRef: episode.ref, noteID: note.id)
            }
            HStack(spacing: WeftSpacing.md) {
                Button(showsTranscript ? "收合逐字稿" : "展開逐字稿片段") { showsTranscript.toggle() }
                Button("看這則怎麼萃取出來") { showsExtraction = true }
            }
            .font(.footnote)
            .underline()
            .foregroundStyle(WeftColor.accent)
            .buttonStyle(.plain)
        }
        .padding(WeftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WeftColor.bgPrimary)
        .weftBorder()
        .sheet(isPresented: $showsExtraction) {
            ExtractionSheet(episode: episode, note: note)
                .presentationDetents([.medium])
        }
    }

    private func block(_ label: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(WeftColor.textSecondary)
            Text(body).font(.callout)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Explains how a note was extracted (text from the site's 關於 page).
private struct ExtractionSheet: View {
    let episode: Episode
    let note: Note

    var body: some View {
        NavigationStack {
            List {
                Section("來源") {
                    LabeledContent("節目", value: episode.showName)
                    LabeledContent("集數", value: episode.title)
                    LabeledContent("時間點", value: note.timeLabel)
                }
                Section("資料怎麼來") {
                    Text("新集數上架後，節目內容由 AI 摘要成一則一則重點（事件、觀點、風險），每一則都附上原片的時間點。提到的股票由程式比對代號與名稱後標上。")
                    Text("AI 摘要與股票比對都可能出錯，引用前請回到原片確認。")
                        .foregroundStyle(WeftColor.textSecondary)
                }
            }
            .navigationTitle("萃取說明")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Figma: Content/Market Context Card (Ready / Insufficient)
struct MarketContextCard: View {
    let context: MarketContext
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.xs) {
            HStack(spacing: WeftSpacing.xs) {
                Text(context.market).font(.headline)
                Text("市場背景").font(.caption.weight(.medium)).foregroundStyle(WeftColor.textSecondary)
                Spacer()
                TickerTag(text: context.status == .ready ? "已就緒" : "資料不足",
                          style: context.status == .ready ? .solid : .line)
            }
            Text(context.line1).font(.footnote)
            if expanded || context.status == .insufficient {
                Text(context.line2).font(.caption.weight(.medium)).foregroundStyle(WeftColor.textSecondary)
            }
            if context.status == .ready {
                Button(expanded ? "收合明細" : "展開明細") {
                    withAnimation(.snappy) { expanded.toggle() }
                }
                .font(.footnote)
                .foregroundStyle(WeftColor.accent)
                .buttonStyle(.plain)
            }
        }
        .padding(WeftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .weftBorder()
    }
}
