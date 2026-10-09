import SwiftUI

struct TimestampView: View {
    @State private var timestampInput = ""
    @State private var pickedDate = Date()
    @State private var timeZoneChoice = 0   // 0 本地，1 UTC
    @State private var formatChoice = 0     // 0..<3 预置，3 自定义
    @State private var customFormat = ""

    static let presets = ["yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd HH:mm", "yyyyMMddHHmmss"]

    private var timeZone: TimeZone {
        timeZoneChoice == 1 ? TimeZone(identifier: "UTC") ?? .current : .current
    }

    private var template: String {
        formatChoice == Self.presets.count ? customFormat : Self.presets[formatChoice]
    }

    private var templateValid: Bool {
        TimestampTool.isValidTemplate(template)
    }

    private var converted: Result<String, ToolError> {
        guard !timestampInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(.invalidTimestamp)
        }
        return TimestampTool.date(fromTimestamp: timestampInput)
            .flatMap { TimestampTool.format($0, timeZone: timeZone, template: template) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 实时时间戳
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let ts = TimestampTool.timestampStrings(from: context.date)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前时间戳").font(.headline)
                        HStack {
                            Text("\(ts.seconds)  (秒)").monospacedDigit()
                            CopyButton(text: ts.seconds)
                            Spacer()
                        }
                        HStack {
                            Text("\(ts.millis)  (毫秒)").monospacedDigit()
                            CopyButton(text: ts.millis)
                            Spacer()
                        }
                    }
                    .padding(8)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                // 时间戳 → 时间
                VStack(alignment: .leading, spacing: 8) {
                    Text("时间戳 → 时间").font(.headline)
                    TextField("输入 10 位（秒）或 13 位（毫秒）时间戳", text: $timestampInput)
                        .textFieldStyle(.roundedBorder)
                    Picker("时区", selection: $timeZoneChoice) {
                        Text("本地").tag(0)
                        Text("UTC").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 200)
                    Picker("格式", selection: $formatChoice) {
                        ForEach(0..<Self.presets.count, id: \.self) { index in
                            Text(Self.presets[index]).tag(index)
                        }
                        Text("自定义").tag(Self.presets.count)
                    }
                    if formatChoice == Self.presets.count {
                        TextField("如 yyyy-MM-dd HH:mm:ss", text: $customFormat)
                            .textFieldStyle(.roundedBorder)
                    }
                    // 模板错误紧贴模板输入展示；为空时不提示（避免切到自定义立刻报红）
                    if formatChoice == Self.presets.count, !customFormat.isEmpty, !templateValid {
                        Text(ToolError.invalidFormatTemplate.userMessage)
                            .foregroundStyle(.red)
                    }
                    // 模板非法时不再显示转换结果区，避免错误重复出现
                    if !timestampInput.isEmpty, templateValid {
                        OutputSection(title: "转换结果", result: converted)
                    }
                }

                // 时间 → 时间戳
                VStack(alignment: .leading, spacing: 8) {
                    Text("时间 → 时间戳").font(.headline)
                    DatePicker("选择时间", selection: $pickedDate)
                    let ts = TimestampTool.timestampStrings(from: pickedDate)
                    HStack {
                        Text("秒：\(ts.seconds)").monospacedDigit()
                        CopyButton(text: ts.seconds)
                        Spacer()
                    }
                    HStack {
                        Text("毫秒：\(ts.millis)").monospacedDigit()
                        CopyButton(text: ts.millis)
                        Spacer()
                    }
                }
                .padding(8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
        }
    }
}
