# MindPulse

> Turn what you read into what you remember.
>
> 让读过的东西，真正变成你的。

---

[English](#english) | [中文](#中文)

---

## English

### What is MindPulse?

MindPulse is an iOS app for busy professionals who read a lot but retain very little. Paste any article or URL, and AI automatically distills it into spaced-repetition flashcards. Review them in just 2 minutes a day — and optionally track your energy level to discover how your learning habits correlate with how you feel.

### Key Features

- **Zero-effort card creation** — Paste text or a URL; AI generates 3–5 Q&A flashcards instantly
- **Spaced repetition (SM-2)** — Cards resurface at scientifically optimal intervals
- **Swipe to review** — Right = remembered, Left = forgot. Done in 2 minutes
- **Energy tracking** — Quick post-review slider (0–10) plus optional mood keywords
- **Weekly insights** — Retention stats, energy trends, and AI-generated observations
- **Multi-model AI** — Choose between Claude, OpenAI, DeepSeek, or Gemini
- **Privacy first** — All data stored locally on device; content is only sent to your chosen AI provider for card generation

### Screenshots

*Coming soon*

### Requirements

- iOS 17.0+
- Xcode 16+
- An API key from one of: Anthropic (Claude), OpenAI, DeepSeek, or Google (Gemini)

### Getting Started

1. Clone the repository:
   ```bash
   git clone git@github.com:polunzh/mindpulse.git
   cd mindpulse
   ```

2. Generate the Xcode project (requires [XcodeGen](https://github.com/yonaskolb/XcodeGen)):
   ```bash
   brew install xcodegen
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open MindPulse.xcodeproj
   ```

4. Select a simulator or device and run.

5. On first launch, choose your AI provider and enter your API key.

### Architecture

```
MindPulse/
├── Models/              # SwiftData models (Source, Card, ReviewLog, DailyStatus, etc.)
├── ViewModels/          # MVVM view models
├── Views/               # SwiftUI views
│   ├── Review/          #   Card review + status recording
│   ├── Add/             #   Content input + card preview
│   ├── Insight/         #   Weekly report + energy chart + AI insights
│   ├── Onboarding/      #   First-launch guide
│   └── Settings/        #   AI provider config, notifications, data management
├── Services/            # Business logic
│   ├── Providers/       #   AI provider implementations (Claude, OpenAI, DeepSeek, Gemini)
│   ├── AIService.swift  #   Unified AI service layer
│   ├── ReviewEngine.swift   # SM-2 spaced repetition algorithm
│   ├── URLParserService.swift # Lightweight HTML content extraction
│   ├── StatsEngine.swift    # Weekly stats & subscription trigger logic
│   └── NotificationService.swift # Local push notifications
└── Extensions/          # Color theme, Date utilities
```

**Tech stack:** SwiftUI · SwiftData · MVVM · SM-2 Algorithm · Swift Charts · URLSession

### Supported AI Providers

| Provider | Models | API Key Format |
|----------|--------|----------------|
| Claude (Anthropic) | claude-sonnet-4-5, claude-haiku-4-5 | `sk-ant-...` |
| OpenAI | gpt-4o, gpt-4o-mini | `sk-...` |
| DeepSeek | deepseek-chat, deepseek-reasoner | `sk-...` |
| Gemini (Google) | gemini-2.0-flash, gemini-2.5-pro | `AIza...` |

### License

MIT

---

## 中文

### MindPulse 是什么？

MindPulse 是一款面向职场人的 iOS App。每天阅读大量文章却记不住？粘贴文本或链接，AI 自动提炼成间隔重复卡片，每天只需 2 分钟滑卡复习。还能在复习后记录当日能量状态，通过数据洞察发现"学什么让你状态更好"。

### 核心功能

- **零门槛制卡** — 粘贴文字或 URL，AI 立即生成 3–5 张问答卡片
- **间隔重复（SM-2）** — 卡片按科学遗忘曲线自动排期复习
- **滑动复习** — 右滑记得、左滑忘了，2 分钟搞定
- **能量追踪** — 复习后用滑块记录能量值（0–10），可选填关键词
- **周报洞察** — 记忆留存率、能量趋势、AI 个性化洞察
- **多模型支持** — 可选 Claude、OpenAI、DeepSeek 或 Gemini
- **隐私优先** — 所有数据本地存储，仅在生成卡片时将内容发送给所选 AI 服务

### 截图

*即将添加*

### 系统要求

- iOS 17.0+
- Xcode 16+
- 以下任一 AI 服务的 API Key：Anthropic (Claude)、OpenAI、DeepSeek、Google (Gemini)

### 快速开始

1. 克隆仓库：
   ```bash
   git clone git@github.com:polunzh/mindpulse.git
   cd mindpulse
   ```

2. 生成 Xcode 工程（需先安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)）：
   ```bash
   brew install xcodegen
   xcodegen generate
   ```

3. 打开工程：
   ```bash
   open MindPulse.xcodeproj
   ```

4. 选择模拟器或真机，运行项目。

5. 首次启动时选择 AI 服务商并输入 API Key。

### 项目结构

```
MindPulse/
├── Models/              # SwiftData 数据模型（Source, Card, ReviewLog, DailyStatus 等）
├── ViewModels/          # MVVM 视图模型
├── Views/               # SwiftUI 视图
│   ├── Review/          #   卡片复习 + 状态记录
│   ├── Add/             #   内容输入 + 卡片预览
│   ├── Insight/         #   周报 + 能量趋势图 + AI 洞察
│   ├── Onboarding/      #   首次使用引导
│   └── Settings/        #   AI 服务配置、通知、数据管理
├── Services/            # 业务逻辑层
│   ├── Providers/       #   AI 服务商实现（Claude, OpenAI, DeepSeek, Gemini）
│   ├── AIService.swift  #   统一 AI 服务调用层
│   ├── ReviewEngine.swift   # SM-2 间隔重复算法
│   ├── URLParserService.swift # 轻量网页正文提取
│   ├── StatsEngine.swift    # 周统计 & 订阅触发逻辑
│   └── NotificationService.swift # 本地推送通知
└── Extensions/          # 主题色、日期工具
```

**技术栈：** SwiftUI · SwiftData · MVVM · SM-2 算法 · Swift Charts · URLSession

### 支持的 AI 服务商

| 服务商 | 可用模型 | API Key 格式 |
|--------|---------|-------------|
| Claude (Anthropic) | claude-sonnet-4-5, claude-haiku-4-5 | `sk-ant-...` |
| OpenAI | gpt-4o, gpt-4o-mini | `sk-...` |
| DeepSeek | deepseek-chat, deepseek-reasoner | `sk-...` |
| Gemini (Google) | gemini-2.0-flash, gemini-2.5-pro | `AIza...` |

### 许可证

MIT
