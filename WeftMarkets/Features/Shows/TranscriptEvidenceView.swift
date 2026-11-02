import SwiftUI

/// Transcript snippets behind a note (`notes/{id}/evidence`), shown under the note
/// card when expanded. States and wording follow weftmarkets.com.
struct TranscriptEvidenceView: View {
    let episodeRef: String
    let noteID: String
    @Environment(\.repository) private var repository
    @State private var state: LoadState<NoteEvidence> = .loading

    private static let emptyReasons = [
        "no_timestamp": "這則重點沒有時間標記，對不到逐字稿。",
        "no_transcript": "這段時間沒有逐字稿片段。",
    ]

    var body: some View {
        Group {
            switch state {
            case .loading:
                caption("讀取逐字稿片段…")
            case .failed(let error):
                HStack {
                    caption(Self.failureText(error))
                    Spacer()
                    Button("重試") { Task { await load() } }
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(WeftColor.accent)
                        .buttonStyle(.plain)
                }
            case .loaded(let evidence) where evidence.segments.isEmpty:
                caption(Self.emptyReasons[evidence.reason ?? "no_transcript"] ?? Self.emptyReasons["no_transcript"]!)
            case .loaded(let evidence):
                VStack(alignment: .leading, spacing: WeftSpacing.xs) {
                    VStack(alignment: .leading, spacing: WeftSpacing.xs) {
                        ForEach(evidence.segments) { segment in
                            Text(Self.line(segment))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(WeftColor.textInverse)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(WeftSpacing.sm)
                    .background(WeftColor.bgInverse)
                    caption("逐字稿原文片段 · 每段只留命中詞前後各 40 字 · 最多六段")
                }
            }
        }
        .task(id: noteID) { await load() }
    }

    private func load() async {
        state = .loading
        do {
            state = .loaded(try await repository.evidence(episodeRef: episodeRef, noteID: noteID))
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error)
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(WeftColor.textSecondary)
    }

    private static func failureText(_ error: Error) -> String {
        if case RepositoryError.notProvided = error { return error.localizedDescription }
        return "暫時讀不到逐字稿片段。"
    }

    /// "[00:12:46] …⟦命中詞⟧…" with hits marked the way the site does. `hits` are
    /// UTF-16 offsets (the API is consumed by JavaScript on the site).
    static func line(_ segment: NoteEvidence.Segment) -> AttributedString {
        var result = AttributedString("[\(segment.time)] ")
        result.foregroundColor = WeftColor.textTertiary

        let utf16 = Array(segment.text.utf16)
        func text(_ range: Range<Int>) -> String { String(decoding: utf16[range], as: UTF16.self) }
        var cursor = 0
        for hit in segment.hits.sorted(by: { $0.lowerBound < $1.lowerBound })
        where hit.lowerBound >= cursor && hit.upperBound <= utf16.count {
            result += AttributedString(text(cursor..<hit.lowerBound))
            var marked = AttributedString("⟦\(text(hit))⟧")
            marked.foregroundColor = WeftColor.highlightSoft
            marked.inlinePresentationIntent = .stronglyEmphasized
            result += marked
            cursor = hit.upperBound
        }
        result += AttributedString(text(cursor..<utf16.count))
        return result
    }
}
