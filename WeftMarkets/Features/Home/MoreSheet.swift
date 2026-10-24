import SwiftUI

/// Figma: 09 更多（Sheet）— 訂閱 / 關於 / 路線圖 / 隱私權 / 聯絡.
/// The subscribe button is not wired yet; the email API comes with the backend work.
struct MoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    private var isValidEmail: Bool {
        email.wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WeftSpacing.md) {
                    VStack(alignment: .leading, spacing: WeftSpacing.sm) {
                        Text("每週一封").font(.headline)
                        Text("留下 email，每週一封上週新集數重點。")
                            .font(.callout)
                            .foregroundStyle(WeftColor.textSecondary)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email").font(.caption.weight(.medium)).foregroundStyle(WeftColor.textSecondary)
                            TextField("you@example.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(.horizontal, WeftSpacing.sm)
                                .frame(minHeight: 50)
                                .weftBorder()
                            Text("免費、隨時可退訂，我們不會把信箱給其他人。")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(WeftColor.textSecondary)
                        }
                        Button("訂閱更新通知") {
                            // TODO: call subscribe endpoint when the API is connected.
                        }
                        .buttonStyle(.weftPrimary)
                        .disabled(!isValidEmail)
                        .opacity(isValidEmail ? 1 : 0.5)
                        Text("訂閱即表示你了解我們如何處理 email，詳見隱私權政策。")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WeftColor.textSecondary)
                    }
                    .padding(WeftSpacing.md)
                    .weftBorder()

                    VStack(spacing: 0) {
                        NavigationLink { AboutView() } label: { ListRowLabel(title: "關於 Weft", systemImage: "doc.text") }
                        NavigationLink { RoadmapView() } label: { ListRowLabel(title: "路線圖", systemImage: "map") }
                        Link(destination: URL(string: "https://next.weftmarkets.com/privacy")!) {
                            ListRowLabel(title: "隱私權政策", systemImage: "lock")
                        }
                        ListRowLabel(title: "聯絡", systemImage: "envelope", value: "信箱尚未公布", showsChevron: false)
                    }
                    .buttonStyle(.plain)

                    Text("Weft 公開測試版 · 內容全部免費、不需要登入 · 非投資建議")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WeftColor.textTertiary)
                }
                .padding(WeftSpacing.md)
            }
            .navigationTitle("更多")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

/// Copy from https://next.weftmarkets.com/about
private struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("Weft 把財經節目整理成可以查證的重點：每一則重點都標出是哪個節目、哪一集、哪個時間點，隨時能回到原片確認。")
            }
            Section("收錄哪些節目") {
                ForEach(MockData.shows) { show in
                    LabeledContent(show.name, value: show.platform?.label ?? "")
                }
            }
            Section("資料怎麼來") {
                Text("新集數上架後，節目內容由 AI 摘要成一則一則重點（事件、觀點、風險），每一則都附上原片的時間點。提到的股票由程式比對代號與名稱後標上。")
            }
            Section("限制") {
                Text("只收錄上面這些節目，不代表整個市場的討論。")
                Text("被提到不等於被推薦；摘要也不代表節目立場，一切以原片為準。")
                Text("AI 摘要與股票比對都可能出錯，引用前請回到原片確認。")
                Text("這裡的內容不是投資建議。")
            }
        }
        .navigationTitle("關於 Weft")
    }
}

/// Copy from https://next.weftmarkets.com/roadmap
private struct RoadmapView: View {
    private let items: [(section: String, code: String, title: String, detail: String)] = [
        ("現在", "R0", "公開測試版", "四個收錄中的節目來源，內容全部免費、不需要登入。"),
        ("現在", "R1", "每週補課", "從每週清單進到單集，讀完有順序的筆記，再跳回原始影片或 podcast 的那一段。"),
        ("現在", "R2", "個股記憶", "搜一家公司，看得到每個節目在不同時間講過它什麼，以及那個時間點的股價。"),
        ("現在", "R3", "注意力雷達（深化）", "讓雷達上的每一個數字都能點回它的來源。"),
        ("接下來", "R1.4", "每週電子報", "把同一份每週整理寄到你的信箱：每週一封，人工整理、審稿後寄出。"),
        ("接下來", "R4", "敘事情報", "把「誰、講了什麼、和什麼有關」整理成可查證的研究素材。"),
        ("之後", "R5", "市場脈絡與個人化", "提及當下的市場狀態、追蹤清單與提醒、個人化的每週摘要。"),
    ]

    var body: some View {
        List {
            ForEach(["現在", "接下來", "之後"], id: \.self) { section in
                Section(section) {
                    ForEach(items.filter { $0.section == section }, id: \.code) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(item.code) · \(item.title)").font(.headline)
                            Text(item.detail).font(.subheadline).foregroundStyle(WeftColor.textSecondary)
                        }
                    }
                }
            }
            Section {
                Text("刻意不寫日期 —— 沒有承諾過的時間就不該寫上來。")
                    .font(.footnote)
                    .foregroundStyle(WeftColor.textSecondary)
            }
        }
        .navigationTitle("路線圖")
    }
}
