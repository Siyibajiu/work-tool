import SwiftUI

/// 工具项：新增工具时在此数组注册，并补充下方 switch 分支
enum ToolItem: String, CaseIterable, Identifiable {
    case timestamp = "时间戳"
    case jwt = "JWT"
    case md5 = "MD5"
    case url = "URL"
    case unicode = "Unicode"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .timestamp: return "clock"
        case .jwt: return "key"
        case .md5: return "number"
        case .url: return "link"
        case .unicode: return "textformat"
        }
    }
}

struct ContentView: View {
    @State private var selection: ToolItem? = .timestamp

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(ToolItem.allCases) { item in
                    Label(item.rawValue, systemImage: item.systemImage)
                        .tag(item)
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .navigationTitle("DevToolbox")
        } detail: {
            switch selection {
            case .timestamp: TimestampView()
            case .jwt: JWTView()
            case .md5: MD5View()
            case .url: URLView()
            case .unicode: UnicodeView()
            case nil: Text("请选择工具").foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 760, idealWidth: 900, minHeight: 520, idealHeight: 600)
    }
}
