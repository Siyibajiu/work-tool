# DevToolbox

macOS 开发者工具箱（Apple Silicon 原生），五个高频小工具，全部本地计算，零第三方依赖。

## 功能

| 工具 | 说明 |
|---|---|
| 时间戳 | 实时秒/毫秒时间戳，时间戳↔时间双向转换，本地/UTC 时区，自定义格式模板 |
| JWT | 解析 Header/Payload，iat/nbf/exp 换算可读时间，过期状态标注 |
| MD5 | 字符串 → 32 位十六进制 MD5，大/小写切换 |
| URL | RFC 3986 编码/解码，一键交换 |
| Unicode | 中文↔Unicode（\uXXXX 与 U+XXXX）双向转换 |

## 系统要求

- macOS 14 (Sonoma) 及以上，通用二进制（arm64 原生 + x86_64，Intel Mac 也可运行）
- 开发需要 Xcode 15+ 与 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）

## 开发

```bash
xcodegen generate                  # 从 project.yml 生成 .xcodeproj
open DevToolbox.xcodeproj          # 用 Xcode 打开，⌘R 运行

# 或命令行
xcodebuild -project DevToolbox.xcodeproj -scheme DevToolbox -destination 'platform=macOS' test
```

## 打包分发

```bash
./scripts/package.sh               # 产出 DevToolbox.zip（Release + ad-hoc 签名）
```

> **注意**：应用未做公证（无付费开发者账号）。收到的朋友首次打开需**右键 → 打开**，
> 或在「系统设置 → 隐私与安全性」中允许。

## 架构

- `DevToolbox/Logic/` 纯逻辑层，`Result<T, ToolError>` 返回，单元测试全覆盖
- `DevToolbox/Views/` SwiftUI 视图薄壳
- 新增工具：加一对 `Logic/` + `Views/` 文件，在 `ContentView.ToolItem` 注册
