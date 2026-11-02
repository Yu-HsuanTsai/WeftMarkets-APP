import Foundation

/// Snapshot of next.weftmarkets.com taken on 2026-10-11 (Asia/Taipei).
/// Every value here was read from the live site; nothing is invented.
/// Episodes carry only their first few notes. Replace with API data later.
enum MockData {
    static let shows: [Show] = [
        Show(id: "you-ting-hao", name: "游庭皓的財經皓角", platform: .youtube, episodesLast7Days: 4),
        Show(id: "jenny", name: "財女珍妮", platform: .youtube, episodesLast7Days: 5),
        Show(id: "gooaye", name: "Gooaye 股癌", platform: .spotify, episodesLast7Days: 2),
        Show(id: "leek-graduate", name: "韭菜畢業班", platform: nil, episodesLast7Days: 1),
    ]

    static let stocks: [String: Stock] = Dictionary(uniqueKeysWithValues: [
        Stock(ticker: "NVDA", name: "NVIDIA Corporation", market: .us, aliases: ["輝達", "NVIDIA"]),
        Stock(ticker: "2330.TW", name: "台積電", market: .tw, aliases: ["台積電", "TSMC", "2330"]),
        Stock(ticker: "AVGO", name: "Broadcom Inc.", market: .us, aliases: ["博通", "Broadcom"]),
        Stock(ticker: "MU", name: "Micron Technology Inc.", market: .us, aliases: ["美光", "Micron"]),
        Stock(ticker: "AMD", name: "Advanced Micro Devices Inc.", market: .us, aliases: ["超微"]),
        Stock(ticker: "MRVL", name: "Marvell Technology Inc.", market: .us, aliases: ["Marvell"]),
        Stock(ticker: "GOOGL", name: "Alphabet Inc.", market: .us, aliases: ["Google"]),
        Stock(ticker: "QCOM", name: "Qualcomm Incorporated", market: .us, aliases: ["高通"]),
        Stock(ticker: "AMZN", name: "Amazon.com Inc.", market: .us, aliases: ["亞馬遜"]),
        Stock(ticker: "INTC", name: "Intel Corporation", market: .us, aliases: ["英特爾"]),
        Stock(ticker: "2454.TW", name: "聯發科", market: .tw, aliases: ["聯發科", "2454"]),
        Stock(ticker: "2317.TW", name: "鴻海", market: .tw, aliases: ["鴻海", "2317"]),
    ].map { ($0.ticker, $0) })

    static func stock(_ ticker: String) -> Stock {
        stocks[ticker] ?? Stock(ticker: ticker, name: ticker, market: ticker.hasSuffix(".TW") ? .tw : .us, aliases: [])
    }

    // MARK: Episodes (節目 · 最新 5 集)

    static let episodes: [Episode] = [
        Episode(
            id: "5kFUTEtsS0Loo68sGym2lG", showID: "gooaye", showName: "Gooaye 股癌", platform: .spotify,
            date: "2026-10-10", title: "EP704 | 🐘",
            summary: "主持人表示，自己除參與曼報Pro外，也以投資人身分參與其他未具名事業；這些事業在第一年就開始賺錢。",
            noteCount: 22, tickerCount: 5, estimatedTokens: 1_711,
            tickers: ["4919.TW", "5274.TW", "AVGO", "MRVL", "NVDA"],
            notes: [
                Note(id: "ep704-1", index: 1, title: "曼報Pro 相關投資與新事業的營收、獲利取捨", startMinute: 4, endMinute: 5,
                     event: "主持人表示，自己除參與曼報Pro外，也以投資人身分參與其他未具名事業；這些事業在第一年就開始賺錢。",
                     view: "主持人原本更重視營收快速成長，認為新事業初期若過早追求獲利，可能犧牲成長性，因此對第一年即獲利感到意外。",
                     risk: "初期追求獲利可能犧牲營收成長。", tickers: []),
                Note(id: "ep704-2", index: 2, title: "當沖、波段操作與融資維持率", startMinute: 13, endMinute: 14,
                     event: "主持人提到，投資人可能受身邊朋友的交易方式影響，包括無本當沖、波段操作及將融資維持率壓得很低；他舉出維持率180%至200%的比較例子。",
                     view: "主持人認為，周遭交易圈的習慣會影響個人的風險感受，甚至讓人覺得原本不算低的維持率過於保守。",
                     risk: "模仿他人的高槓桿操作，可能使風險承受方式偏離自己的規劃。", tickers: []),
                Note(id: "ep704-3", index: 3, title: "財報、月營收追蹤頻率與博通投片量", startMinute: 13, endMinute: 14,
                     event: "主持人提到，有些投資人追蹤財報與月營收，並曾向一名外資業者詢問博通最新投片量；對方表示不追蹤這類短期數字，認為長期方向可能不因其間的上修或下修而改變。",
                     view: "主持人逐漸接受不必對每次數字變動立即反應，但也承認過去持股套牢時，曾以長期故事安慰自己。",
                     risk: "短期估計可能反覆上修、下修；持股套牢也可能影響對長期論點的判斷。", tickers: ["AVGO"]),
            ]
        ),
        Episode(
            id: "WUFheGrNBWM", showID: "jenny", showName: "財女珍妮", platform: .youtube,
            date: "2026-10-09", title: "2026/10/09(五) 費半為何又大跌？OpenAI數字縮水，AI基建又要重估嗎？",
            summary: "道瓊工業指數上漲0.1%，S&P 500 下跌0.5%，NASDAQ 100 下跌1.4%，費城半導體指數下跌3.4%，羅素2000指數上漲0.03%。AI 相關公司及半導體股的跌勢明顯重於大盤。",
            noteCount: 28, tickerCount: 9, estimatedTokens: 2_178,
            tickers: ["2330.TW", "AMD", "AVGO", "CRWV", "GOOGL", "MSFT"],
            notes: [
                Note(id: "jenny1009-1", index: 1, title: "美股主要指數與科技股跌勢", startMinute: 1, endMinute: 2,
                     event: "道瓊工業指數上漲0.1%，S&P 500 下跌0.5%，NASDAQ 100 下跌1.4%，費城半導體指數下跌3.4%，羅素2000指數上漲0.03%。AI 相關公司及半導體股的跌勢明顯重於大盤。",
                     view: "珍妮認為，科技股承受的壓力不只來自殖利率與資金成本，投資人也在重新評估企業未來收入、支出與估值。",
                     risk: "AI 相關公司的成長預期與合理股價可能遭到下修。", tickers: []),
                Note(id: "jenny1009-2", index: 2, title: "台積電營收與 ADR 股價", startMinute: 2, endMinute: 3,
                     event: "台積電第三季營收創歷史紀錄，9月營收年增55%；其 ADR 昨天下跌約3%，費城半導體指數跌逾3%。",
                     view: "珍妮認為台積電營運仍穩健，但基本面成長未能阻止股價隨半導體族群下跌。",
                     risk: "產業消息與估值調整可能使股價短期走勢偏離營收表現。", tickers: ["2330.TW"]),
                Note(id: "jenny1009-3", index: 3, title: "OpenAI 年化營收數字與 AI 基建預期", startMinute: 2, endMinute: 3,
                     event: "市場消息指出，OpenAI 截至9月底的年化營收接近500億美元，低於先前流傳的700億美元數字；兩者相差約200億美元。",
                     view: "珍妮認為這項落差是半導體與 AI 相關股票遭拋售的重要原因，需要釐清數字的計算方式。",
                     risk: "若市場據此調整 OpenAI 的成長預期，資料中心與晶片採購規模也會受到質疑。", tickers: []),
            ]
        ),
        Episode(
            id: "_dfkO0oKRvg", showID: "you-ting-hao", showName: "游庭皓的財經皓角", platform: .youtube,
            date: "2026-10-08", title: "2026/10/8(四)全球政府都缺錢!高利率時代誰來買單?AI時代 企業賺錢、政府缺錢、人民沒錢?【早晨財經速解讀】",
            summary: "美股前天創高後，昨天收低；長天期公債殖利率則持續攀升。S&P 500、NASDAQ 先前創高，歐洲 STOXX 600 距歷史高位約剩 4%，上週以來跌幅約 2% 至 3%。",
            noteCount: 36, tickerCount: 4, estimatedTokens: 2_800,
            tickers: ["AMZN", "QCOM"],
            notes: [
                Note(id: "yth1008-1", index: 1, title: "美股與全球債市對通膨、利率的不同定價", startMinute: 0, endMinute: 2,
                     event: "美股前天創高後，昨天收低；長天期公債殖利率則持續攀升。S&P 500、NASDAQ 先前創高，歐洲 STOXX 600 距歷史高位約剩 4%，上週以來跌幅約 2% 至 3%。",
                     view: "皓哥認為，債市正在反映較高通膨、財政風險及較緊貨幣政策，股市對油價與通膨的反應卻較小。即使股價未大跌，若獲利成長較快，本益比仍可能下降。",
                     risk: "高利率持續可能壓縮股票估值；股債對總體經濟的定價分歧仍待觀察。", tickers: ["QCOM"]),
                Note(id: "yth1008-2", index: 2, title: "法國、義大利公債與德債利差", startMinute: 1, endMinute: 2,
                     event: "節目指出，上週法國 10 年期公債相對德債的利差單週擴大 32 個基點，為 1990 年德國統一以來最大單週升幅；義大利相對德債的利差也擴大至 23 個基點。法國股市面臨較重賣壓。",
                     view: "皓哥認為，歐洲債市承受的壓力尚未同等程度反映在整體股市。",
                     risk: "主權債利差持續擴大，可能加重歐洲市場壓力。", tickers: []),
                Note(id: "yth1008-3", index: 3, title: "道瓊工業指數、NASDAQ、S&P 500 與費城半導體指數", startMinute: 2, endMinute: 3,
                     event: "昨天道瓊工業指數下跌 341 點、NASDAQ 下跌 61 點、S&P 500 下跌 17 點；費城半導體指數下跌 151 點、跌幅 1.15%，收在 13,066 點。",
                     view: "皓哥認為，前天美股才創高，昨天的回檔尚可接受，股價也未呈現特別沉重的跌勢。",
                     risk: nil, tickers: []),
            ]
        ),
        Episode(
            id: "f_67nMgBeNg", showID: "jenny", showName: "財女珍妮", platform: .youtube,
            date: "2026-10-08", title: "2026/10/08(四) FED還想升息AI行情撐得住？",
            summary: "節目列出的前一交易日收盤變動為：道瓊工業指數跌0.7%、S&P 500跌0.2%、NASDAQ 100跌0.2%、費城半導體指數跌1.2%、羅素2000跌0.6%。",
            noteCount: 31, tickerCount: 18, estimatedTokens: 2_411,
            tickers: ["2383.TW", "2454.TW", "2492.TW", "3081.TW", "3532.TW"],
            notes: [
                Note(id: "jenny1008-1", index: 1, title: "道瓊工業指數、S&P 500、NASDAQ 100、費城半導體指數與羅素2000", startMinute: 0, endMinute: 1,
                     event: "節目列出的前一交易日收盤變動為：道瓊工業指數跌0.7%、S&P 500跌0.2%、NASDAQ 100跌0.2%、費城半導體指數跌1.2%、羅素2000跌0.6%。",
                     view: "珍妮認為各指數呈現弱勢或修正格局，市場開始擔心先前創高與反彈是否告終。",
                     risk: "先前的上漲行情能否延續仍有疑問。", tickers: []),
                Note(id: "jenny1008-2", index: 2, title: "AI資金流、高利率與企業擴張融資", startMinute: 1, endMinute: 2,
                     event: "節目提到盤後有博通與OpenAI合作及籌措更大規模資金的消息；高利率環境下，擴張資本支出的企業需要尋找融資來源。",
                     view: "珍妮認為資金流向AI的趨勢尚未改變，但現金充裕或需要取得訂單的合作方，可能需要扮演資金提供者；這究竟是機會或危機仍是市場討論焦點。",
                     risk: "利率上升可能提高企業成本、壓抑投資需求。", tickers: ["AVGO"]),
                Note(id: "jenny1008-3", index: 3, title: "聯準會9月會議紀要與政策利率", startMinute: 2, endMinute: 3,
                     event: "節目稱聯準會9月已升息一碼，當時利率區間為3.75%至4%；其後公布的9月會議紀要顯示，多數與會官員認為年底前可能仍須升息，但未指向特定時點。",
                     view: "珍妮認為聯準會態度是判斷企業資金成本及後續投資的重要因素。",
                     risk: "年底是否再次升息、何時升息，仍未確定。", tickers: []),
            ]
        ),
        Episode(
            id: "wM7uDRpaC-g", showID: "you-ting-hao", showName: "游庭皓的財經皓角", platform: .youtube,
            date: "2026-10-07", title: "2026/10/7(三)輝達衝6兆市值 估值更便宜?AI越燒越多 錢從哪裡來？【早晨財經速解讀】",
            summary: "週二美股全面收高，原油價格趨穩、公債殖利率回落；S&P 500 突破7,800點，今年第28次創歷史新高。",
            noteCount: 31, tickerCount: 14, estimatedTokens: 2_411,
            tickers: ["2317.TW", "AAPL"],
            notes: [
                Note(id: "yth1007-1", index: 1, title: "美股、S&P 500 與原油及公債殖利率", startMinute: 0, endMinute: 1,
                     event: "週二美股全面收高，原油價格趨穩、公債殖利率回落；S&P 500 突破7,800點，今年第28次創歷史新高。主持人回顧，該指數去年創高39次、前年57次，2021年70次、2020年33次。",
                     view: "皓哥認為，美股收復重大跌幅後，可能進入連續多年的創高階段。",
                     risk: nil, tickers: []),
                Note(id: "yth1007-2", index: 2, title: "S&P 500 創高與 AMD、美超微、Intel 的表現分化", startMinute: 1, endMinute: 2,
                     event: "從9月中旬低點以來，AMD、美超微及 Intel 漲幅均超過20%；同一期間，部分中小型股仍承受賣壓。",
                     view: "皓哥提醒，S&P 500 創高不代表多數股票同步上漲。",
                     risk: "指數強勢可能掩蓋個股表現分化。", tickers: ["AMD", "INTC", "SMCI"]),
                Note(id: "yth1007-3", index: 3, title: "S&P 500 等權指數、公用事業與非必需消費類股", startMinute: 2, endMinute: 3,
                     event: "S&P 500 等權指數距歷史高點仍低近5%；約500檔成分股中，僅三分之一自9月中旬上漲，三分之二下跌。公用事業類股曾在8月下跌近10%，非必需消費類股目前約下跌5%。",
                     view: "皓哥將指數創高、但上漲股票有限，視為當前市場的主要矛盾。",
                     risk: "等權指數及多數成分股尚未跟上大型股漲勢。", tickers: []),
            ]
        ),
    ]

    // MARK: 本週

    static let markets: [MarketContext] = [
        MarketContext(market: "台股", status: .ready,
                      line1: "Benchmark：0050.TW 上升趨勢 · ^TWII 上升趨勢",
                      line2: "平台追蹤股廣度：風險偏好、趨勢明確 · SMA200 以上 277 / 282 · 98.23%"),
        MarketContext(market: "美股", status: .insufficient,
                      line1: "平台追蹤股廣度：尚無對應的已發布背景",
                      line2: "參考價格日 2026-10-08 · 背景原因：CONTEXT_SESSION_MISSING"),
    ]

    static let weekly = WeeklySummary(
        dateLabel: "2026-10-11 週日", week: "W41", period: "2026-10-05 – 2026-10-11",
        episodes: 12, notes: 355, tickers: 66, showsWithNewEpisodes: 4, showsTotal: 4,
        topByEpisodes: [
            StockRanking(rank: 1, stock: stock("NVDA"), noteCount: nil, episodeCount: 11, showCount: nil),
            StockRanking(rank: 2, stock: stock("2330.TW"), noteCount: nil, episodeCount: 9, showCount: nil),
            StockRanking(rank: 3, stock: stock("AVGO"), noteCount: nil, episodeCount: 8, showCount: nil),
            StockRanking(rank: 4, stock: stock("MU"), noteCount: nil, episodeCount: 7, showCount: nil),
            StockRanking(rank: 5, stock: stock("AMD"), noteCount: nil, episodeCount: 6, showCount: nil),
        ],
        latestEpisode: episodes[0],
        markets: markets
    )

    // MARK: 雷達

    static let radar = RadarSnapshot(
        period: "2026-10-04 – 2026-10-10",
        leader: StockRanking(rank: 1, stock: stock("NVDA"), noteCount: 32, episodeCount: 11, showCount: 4),
        top: [
            StockRanking(rank: 1, stock: stock("NVDA"), noteCount: 32, episodeCount: 11, showCount: 4),
            StockRanking(rank: 2, stock: stock("2330.TW"), noteCount: 25, episodeCount: 9, showCount: nil),
            StockRanking(rank: 3, stock: stock("AVGO"), noteCount: 21, episodeCount: 8, showCount: nil),
        ],
        totalRanked: 15
    )

    static let themes = ThemeSnapshot(
        weekStart: "2026-09-28", analyzedEpisodes: 105, publishedEpisodes: 118, coverageSufficient: false,
        themes: [
            NarrativeTheme(rank: 1, name: "ai", mentionCount: 134, shareOfVoice: 0.45,
                           representativeTickers: ["NVDA", "META", "AMD", "GOOGL"], wowNote: "週比值：資料不足"),
            NarrativeTheme(rank: 2, name: "半導體", mentionCount: nil, shareOfVoice: 0.11,
                           representativeTickers: ["AVGO", "MRVL", "2330.TW", "2344.TW"], wowNote: nil),
            NarrativeTheme(rank: 3, name: "美股", mentionCount: nil, shareOfVoice: 0.10,
                           representativeTickers: ["ASML", "KLAC"], wowNote: nil),
        ]
    )

    // MARK: 個股

    static let stockDetails: [String: StockDetail] = [
        "NVDA": StockDetail(
            stock: stock("NVDA"), dataUpdated: "資料為最近一次更新 2026-10-10 · 產出於 2026-10-11 11:50",
            mentions: [
                KOLMention(showName: "游庭皓的財經皓角", date: "2026-10-07", topic: "NVIDIA 市值、S&P 500 貢獻與營收預估",
                           priceThen: "239.24（10-06）", priceNow: "229.28 USD（10-09）", change: "-4.16%"),
                KOLMention(showName: "財女珍妮", date: "2026-10-09", topic: "OpenAI、NVIDIA、Oracle 與 AI 資料中心需求鏈",
                           priceThen: "230.48（10-08）", priceNow: "229.28 USD（10-09）", change: "-0.52%"),
                KOLMention(showName: "Gooaye 股癌", date: "2026-10-10", topic: "NVIDIA 早期 AI 業務，以及其他 XPU、互連業者展望",
                           priceThen: "229.28", priceNow: "229.28 USD（10-09）", change: "+0.00%"),
            ],
            notes12w: 354, episodes12w: 118, shows12w: 4,
            priceState: "趨勢中", narrativeTemperature: "溫熱", narrativeXPrice: "溫熱 × 趨勢中",
            preMentionReturn: "+26.19%",
            market: markets[1]
        ),
    ]
}
