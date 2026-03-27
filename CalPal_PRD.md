# CalPal — Product Requirements Document
**版本：** v1.3
**日期：** 2026-03-27
**作者：** Shawn
**状态：** ✅ 已确认，可开始开发
**配合文档：** CalPal_UI_SPEC.md / CalPal_SwiftUI_Guide.md

### 版本变更记录
| 版本 | 日期 | 变更内容 |
|------|------|---------|
| v1.0 | 2026-03-27 | 初始正式版 |
| v1.1 | 2026-03-27 | V1 移除 Google Calendar；V1 移除 Claude API 意图解析；Claude API 保留框架占位 |
| v1.2 | 2026-03-27 | V1 重定义为最小可用版：移除 Morning/Evening Review、iPad、习惯分析、CloudKit，同步保留本地 AI + Apple Calendar 核心闭环 |
| v1.3 | 2026-03-27 | 新增 UI / SwiftUI 指导文档链接；界面实现统一收敛为系统风格主页 + Unified Split View |

---

## 1. 产品定位

### 1.1 一句话描述
CalPal 是一个以隐私为核心、AI 运行在本地的 iPhone 日程助理。V1 聚焦验证「语音/文字输入 -> 本地 AI 解析 -> Apple Calendar 写入」这条最小可用闭环。

### 1.2 V1 核心目标
- 验证本地 AI 解析自然语言日程是否足够可用
- 验证语音 PTT 交互是否顺手
- 验证 Apple Calendar 读写闭环是否稳定
- 在不接入任何云端 AI 的前提下，完成可演示、可日常轻量使用的最小版本

### 1.3 当前不追求的目标
- 不在 V1 解决“真正懂你”的长期习惯学习能力
- 不在 V1 提供早间规划、晚间复盘
- 不在 V1 提供 iPad 体验
- 不在 V1 提供跨设备同步
- 不在 V1 提供云端 AI fallback

### 1.4 技术可行性验证（Quick Demo 已确认）
以下技术路线已通过真机 Demo 验证可行：
- ✅ Apple Foundation Models 本地解析自然语言 -> 结构化日历事件
- ✅ EventKit 读写 Apple Calendar
- ✅ Apple Speech Recognition 语音转文字
- ✅ 长按 FAB 按钮 PTT 交互
- ✅ Foundation Models 在真机上正常加载（需 Apple Intelligence 已开启）

---

## 2. 目标用户

**V1 阶段：** 单用户（Shawn 本人），美国地区，iPhone 单设备优先  
**V2 阶段：** 再扩展到更完整的个人效率助手体验

**用户画像：**
- 双语使用者（中文为主，英文可切换）
- 主要使用 Apple Calendar
- 对云端 AI 和第三方 SaaS 隐私有顾虑
- 更在意输入和写入效率，而不是复杂协作功能

---

## 3. 功能范围

### 3.1 V1 MVP 功能

#### F1：语音 + 文字输入
- **主要交互：长按 FAB 语音输入（PTT）**
  - 长按开始录音
  - 松手结束并自动提交识别结果
  - 上滑取消录音
  - 录音时主日历仍可上下滚动
- **辅助交互：文字输入**
  - 点击 `Type` 按钮打开输入框
  - 用于补充语音无法准确表达的细节
- **语言支持：**
  - 中文或英文单语
  - 首次启动时选择
  - V1 不支持中英混切

#### F2：本地 AI 意图解析

**V1 架构：纯本地，无任何外部 AI API 调用**

```text
用户输入（语音/文字）
        ↓
Foundation Models（本地）
        ↓
CalendarIntent
        ├── 成功 -> 执行写入策略
        └── 失败 -> 提示用户重新表述
```

**Foundation Models 输出结构：**
```swift
@Generable
struct CalendarIntent {
    let action: String        // "add" / "delete" / "modify"
    let title: String
    let startISO: String
    let endISO: String
    let isRecurring: Bool
    let recurrenceRule: String?
    let location: String?
    let notes: String?
}
```

**错误处理：**
- Foundation Models 不可用（未开启 Apple Intelligence）-> 提示用户开启
- Foundation Models 解析失败 -> Toast：「未能理解，请重新表述」
- **V1 不做任何云端 AI fallback**

#### F3：智能写入策略

| 场景 | 行为 |
|------|------|
| 无冲突且用户明确表达添加意图 | 直接写入，不二次确认 |
| 与已有日程冲突 | 弹出确认卡 |
| 周期性事件首次创建 | 弹出确认卡 |
| 涉及他人的事件 | 弹出确认卡 |
| 删除任何事件 | 必须二次确认 |
| 删除周期性事件 | 额外选择：仅此次 / 此后所有 / 全部删除 |

#### F4：Apple Calendar 读写
- V1 仅支持 Apple Calendar（EventKit）
- 支持读取、写入、修改、删除
- V1 不支持 Google Calendar
- V1 不做多日历源管理

#### F5：Onboarding
- 首次启动语言选择
- 权限申请：日历、麦克风、语音识别
- Apple Intelligence 状态检测
- 若本地 AI 不可用，明确提示：
  - 本地 AI 功能暂不可用
  - 云端 AI 功能尚未开放

#### F6：基础设置页
- 语音输入语言
- 本地 AI 状态
- Claude API 入口（置灰、不可用、仅占位）
- 权限与隐私说明

---

### 3.2 V2 功能（本版不做）

- Morning Review / Morning Briefing
- Evening Review
- HabitAnalyzer / UserPreference 画像
- SwiftData 持久化增强
- CloudKit / iCloud 同步
- iPad 适配
- 本地推送提醒
- Google Calendar 支持
- Claude API 深度规划与复盘
- Siri 快捷指令
- Widget
- 中英混切语音识别
- 更复杂的周期规则解析

---

### 3.3 明确不做（V1 Out of Scope）

- 云端 AI fallback
- 早晚复盘
- 习惯学习与画像
- 跨设备同步
- iPad UI
- Google Calendar
- 团队日历 / 多用户协作
- TODO 管理
- 独立账号体系 / 自建后端
- Android 版本

---

## 4. 技术架构

### 4.1 技术选型

| 层级 | 技术 | 版本要求 | V1 状态 |
|------|------|---------|---------|
| UI 框架 | SwiftUI | iOS 18.4+ | ✅ |
| 本地 AI | Apple Foundation Models | iOS 18.4+ | ✅ |
| 语音识别 | Apple Speech Recognition | iOS 18.4+ | ✅ |
| Apple 日历 | EventKit | iOS 18.4+ | ✅ |
| 云端 AI | Anthropic Claude API | — | 🔘 仅框架占位，V2 实现 |
| 数据持久化 | SwiftData | 可选 | 🔘 V1 非必须 |
| 云同步 | CloudKit Private DB | — | ⏸ V2 实现 |

### 4.2 V1 推荐项目结构

```text
CalPal/
├── CalPalApp.swift
├── Views/
│   ├── ContentView.swift
│   ├── ConfirmationSheet.swift
│   ├── OnboardingView.swift
│   └── SettingsView.swift
├── Services/
│   ├── CalendarManager.swift
│   ├── VoiceInputManager.swift
│   ├── AIIntentParser.swift
│   └── ClaudeAPIService.swift
├── Models/
│   └── CalendarIntent.swift
├── Utils/
│   └── DateUtils.swift
└── Resources/
    └── Info.plist
```

**实现参考文档：**
- `CalPal_UI_SPEC.md`：Paper 与视觉交互规范
- `CalPal_SwiftUI_Guide.md`：SwiftUI 组件拆分、状态模型与页面实现建议

### 4.3 重要接口与类型

```swift
protocol AIService {
    func parseIntent(_ input: String) async -> CalendarIntent?
}

final class FoundationModelsService: AIService {
    // V1 实现
}

final class ClaudeAPIService: AIService {
    func parseIntent(_ input: String) async -> CalendarIntent? {
        // TODO: V2
        return nil
    }
}
```

说明：
- `AIService` 保留，便于后续扩展
- V1 运行时只接入 `FoundationModelsService`
- `ClaudeAPIService` 仅作为接口占位，不参与任何 fallback
- `DailyLog`、`UserPreference`、`ConversationMessage` 等持久化模型不是 V1 必需交付项

### 4.4 已知风险与 V1 应对方案

| 风险 | 优先级 | V1 应对方案 |
|------|--------|-----------|
| Foundation Models 不可用 | 高 | 检测可用性并提示用户开启，不做 fallback |
| Foundation Models 解析失败 | 中 | Toast 提示用户重新表述 |
| 周期规则解析不稳定 | 中 | 通过确认卡兜底；复杂表达允许失败 |
| Apple Calendar 时区处理 | 中 | 建立统一 `DateUtils` 处理层 |
| 语音识别不准 | 中 | 提供文字输入作为补充路径 |

---

## 5. 用户交互流程

### 5.1 核心交互：添加日程

```text
用户长按 FAB
        ↓
录音中（日历仍可滚动）
        ↓
松手 -> 语音转文字
        ↓
Foundation Models 解析
        ├── 成功 -> CalendarIntent
        │       ├── 无冲突 -> 直接写入 -> Toast「已添加」
        │       └── 有冲突 / 周期 -> 弹出确认卡
        └── 失败 -> Toast「未能理解，请重新表述」
```

### 5.2 删除确认

```text
用户：取消明天下午的会议
        ↓
Foundation Models 识别为删除
        ↓
弹出确认卡：
「确认删除：明天下午 3:00 项目会议？」
[删除] [取消]
```

### 5.3 本地 AI 不可用

```text
用户首次启动或尝试解析
        ↓
检测到 Apple Intelligence 不可用
        ↓
提示：
「请在设置中开启 Apple Intelligence」
「云端 AI 功能暂未开放」
```

---

## 6. 非功能性需求

| 指标 | 目标 |
|------|------|
| 语音识别响应 | < 1.5 秒 |
| Foundation Models 解析 | < 2 秒（真机） |
| EventKit 读写 | < 0.5 秒 |
| 最低 iOS 版本 | iOS 18.4 |
| 支持设备 | iPhone |
| 数据隐私 | V1 完全不依赖第三方服务器 |

---

## 7. 开发里程碑

### Phase 0：技术验证 ✅ 已完成
- [x] Foundation Models 真机验证
- [x] EventKit 读写验证
- [x] Speech Recognition 验证
- [x] FAB PTT 交互验证

### Phase 1：主框架（第 1 周）
- [ ] 主日历视图
- [ ] Onboarding
- [ ] 权限申请
- [ ] 基础设置页

### Phase 2：输入与解析（第 2 周）
- [ ] FAB 语音输入完整流程
- [ ] 文字输入
- [ ] Speech Recognition 接入
- [ ] Foundation Models 解析

### Phase 3：日历写入闭环（第 3 周）
- [ ] EventKit 新增 / 修改 / 删除
- [ ] 智能写入策略
- [ ] 删除二次确认
- [ ] 周期事件确认卡
- [ ] 错误提示

### Phase 4：联调与打磨（第 4 周）
- [ ] Claude API 灰度占位
- [ ] 真机联调
- [ ] 边界问题修复
- [ ] 基础 UI 打磨

**周期估算：**
- 单人全职：2-4 周
- 2 周可出内部验证版
- 4 周可出更稳的最小可用版

---

## 8. 测试与验收

### 8.1 必测场景
- 首次启动权限链路
- Apple Intelligence 可用 / 不可用
- 语音输入成功 / 取消 / 识别失败
- 文字输入解析成功 / 失败
- 新增事件无冲突直接写入
- 删除事件二次确认
- 周期事件创建需确认
- 错误提示与 Claude 置灰状态一致

### 8.2 暂不纳入 V1 验收
- 跨设备同步
- 习惯画像
- Morning Review / Evening Review
- iPad 适配

---

## 9. 成本估算（V1）

| 项目 | 费用 | 说明 |
|------|------|------|
| Apple Foundation Models | 免费 | 本地运行 |
| Apple Speech Recognition | 免费 | 本地运行 |
| Claude API | $0 | V1 不调用 |
| Google Calendar API | $0 | V1 不使用 |
| Apple Developer Program | $99/年 | 真机、TestFlight、上架所需 |

**V1 合计：$0/月 + $99/年**

---

## 10. 当前基线结论

- V1 是一个 **iPhone 单设备、本地 AI、Apple Calendar only** 的最小可用版
- V1 的成功标准不是“完整智能日程助理”，而是“核心闭环能稳定跑通”
- Claude API 在 V1 只保留 UI 和代码占位，**不可用、不可 fallback、不可偷偷接管解析**

---

*本文档 v1.2 为当前开发基准版本，配合 CalPal_UI_SPEC.md 使用。*
