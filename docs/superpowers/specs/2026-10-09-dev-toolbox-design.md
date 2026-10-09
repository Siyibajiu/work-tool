# DevToolbox 设计文档

日期：2026-10-09
状态：已确认

## 背景与目标

为开发者打造一个 macOS（Apple Silicon）本地工具箱应用，包含 5 个高频小工具：
时间戳转换、JWT 解析、MD5、URL 编码解码、Unicode/中文互转。全部功能本地计算，
零网络请求，零第三方依赖。

## 决策记录

| 决策点 | 结论 | 理由 |
|---|---|---|
| 应用形态 | SwiftUI 原生窗口应用 | 原生质感，性能好，无需前端环境 |
| 分发方式 | ad-hoc 签名，zip 发给朋友 | 无付费开发者账号，接受右键打开限制 |
| 架构 | 单 Xcode 项目单 target，Logic/Views 分层 | 规模小，最简单，可测试性不损失 |
| 最低系统 | macOS 14 (Sonoma) | 使用 NavigationSplitView 等新 API |
| MD5 范围 | 仅字符串 | 最常用场景，文件哈希暂不需要 |
| JWT 范围 | 解码 + 过期检查，不做签名验证 | 验证需 secret/公钥，复杂度高收益低 |
| 依赖 | 仅 SwiftUI / Foundation / CryptoKit | 系统框架足够覆盖全部需求 |

## 总体架构

```
DevToolbox/
├── DevToolboxApp.swift          # @main 入口
├── Logic/                       # 纯逻辑层，无 UI 依赖
│   ├── TimestampTool.swift
│   ├── JWTTool.swift
│   ├── MD5Tool.swift
│   ├── URLTool.swift
│   ├── UnicodeTool.swift
│   └── ToolError.swift          # 统一错误枚举，中文可读描述
├── Views/
│   ├── ContentView.swift        # NavigationSplitView 侧边栏（数据驱动数组）
│   ├── TimestampView.swift
│   ├── JWTView.swift
│   ├── MD5View.swift
│   ├── URLView.swift
│   └── UnicodeView.swift
└── DevToolboxTests/             # XCTest，仅测 Logic 层
```

模式：MV（Logic 纯函数 + View 薄壳）。Logic 层函数返回 `Result<T, ToolError>`，
`ToolError` 携带面向用户的中文错误文案。

侧边栏为数据驱动数组，未来加新工具（Base64、UUID 等）只需新增 Logic + View
两个文件并在数组中注册一行。

## 功能规格

### 1. 时间戳（增强版）

- 顶部实时显示当前时间戳（秒级 + 毫秒级），每秒刷新，各带一键复制
- 时间戳 → 时间：自动识别 10 位（秒）/ 13 位（毫秒）；非法输入或超出
  可表示范围时红字提示
- 时间 → 时间戳：日期选择器选时间，同时输出秒级与毫秒级结果
- 时区下拉：本地 / UTC，转换结果跟随所选时区
- 格式模板：预置 `yyyy-MM-dd HH:mm:ss`、`yyyy/MM/dd HH:mm`、
  `yyyyMMddHHmmss` 三档 + 自定义输入（DateFormatter 语法）；模板非法时
  红字提示并回退默认格式

### 2. JWT 解析

- 粘贴 token 后实时解析，Header / Payload 分别以格式化 JSON 展示
- Payload 中 `exp` / `nbf` / `iat` 字段（若为数字时间戳）额外显示对应可读时间
- `exp` 已过期时整块红色标注「已过期 xx 分/小时/天」；未过期显示剩余时间
- token 结构非法（段数不为 3、Base64 解码失败、JSON 解析失败）时显示
  「不是合法的 JWT」，不崩溃
- Header / Payload JSON 各带一键复制

### 3. MD5

- 输入任意文本（含多行）实时计算，输出 32 位十六进制 MD5，默认小写
- 提供大写/小写切换
- 输入为空时结果区显示占位文案
- 一键复制

### 4. URL 编码解码

- 编码：RFC 3986，非保留字符以外全部转 `%XX`（中文按 UTF-8 字节）
- 解码：`%XX` 还原；非法序列（如 `%ZZ`、不完整 `%`）红字提示，不崩溃
- 一键复制、一键「交换输入输出」

### 5. Unicode ↔ 中文

- 中文 → Unicode：每个非 ASCII 字符输出 `\uXXXX` 形式，ASCII 字符原样保留
- Unicode → 中文：识别 `\uXXXX` 与 `U+XXXX` 两种写法，可混合普通文本
- 非法序列红字提示
- 一键复制、双向交换

## UI 设计

- `NavigationSplitView`：左侧侧边栏（图标 + 名称），右侧当前工具详情
- 每个工具页统一模式：输入区（上）→ 操作（中）→ 结果区 + 复制按钮（下）
- 复制成功反馈：按钮文字变「已复制 ✓」约 1.5 秒后还原
- 窗口默认 900×600，可自由缩放；深色模式跟随系统
- 本期不做全局快捷键（YAGNI）

## 错误处理

- 所有用户输入视为不可信：任何解析失败都不崩溃，统一红字提示
- Logic 层返回 `Result<T, ToolError>`；`ToolError` 关联中文用户文案
- View 层仅渲染 Result，不做解析逻辑

## 测试策略

- Logic 层单元测试全覆盖，每个工具至少包含：
  - 正常路径
  - 边界：空输入、非法格式、13 位时间戳、超范围数字、坏 % 序列、
    段数不对的 JWT、混合文本的 Unicode
- View 层不写 UI 测试，人工验收
- 验收标准：`xcodebuild test` 全绿 + 5 个功能手动过一遍

## 构建与分发

- 构建：Xcode 或 `xcodebuild -scheme DevToolbox -configuration Release`
- 架构：arm64（Apple Silicon 原生）
- 打包：Release 构建 → ad-hoc 签名 → zip 压缩 `.app` 发出
- 已知限制：朋友首次打开需右键 → 打开（无付费开发者账号无法公证），
  写入 README 说明

## 明确不做（本期）

- MD5 文件哈希
- JWT 签名验证
- 全局快捷键 ⌘K
- Base64 / UUID 等额外工具（架构已预留扩展点）
- 公证 / App Store 上架
