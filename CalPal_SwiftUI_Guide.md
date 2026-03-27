# CalPal — SwiftUI Implementation Guide
**版本：** v1.0
**日期：** 2026-03-27
**配合文档：** CalPal_PRD.md / CalPal_UI_SPEC.md

---

## 1. 目标

这份文档用于把 Paper 中已经确认的界面快速映射成可实现的 SwiftUI 结构，减少实现阶段重新做信息架构决策。

V1 只聚焦三类页面：
- 主日历页
- 统一日程对话页 `Unified Split View`
- Onboarding / Settings 辅助页

---

## 2. 推荐视图结构

```text
CalPalApp
└── RootView
    ├── MainCalendarScreen
    ├── UnifiedConversationScreen
    ├── OnboardingFlowView
    └── SettingsView
```

推荐拆分：

```text
Views/
├── Screens/
│   ├── MainCalendarScreen.swift
│   ├── UnifiedConversationScreen.swift
│   ├── OnboardingFlowView.swift
│   └── SettingsView.swift
├── Components/
│   ├── CalendarHeaderView.swift
│   ├── DatePagerView.swift
│   ├── TimelineView.swift
│   ├── EventBlockView.swift
│   ├── FloatingInputBar.swift
│   ├── RecordingOverlayView.swift
│   ├── SplitPreviewCard.swift
│   ├── ConversationBubbleView.swift
│   └── ConfirmationSheetView.swift
└── Support/
    ├── CalendarTheme.swift
    └── LayoutMetrics.swift
```

---

## 3. 关键状态模型

```swift
enum FABState {
    case idle
    case recording
    case processing
}

enum ConversationVariant {
    case planning
    case review
}

struct DayPage: Identifiable, Hashable {
    let id: Date
    let date: Date
    let hasEvents: Bool
}

struct CalendarEventUIModel: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let color: Color
    let isSuggested: Bool
}

struct ConversationAction {
    let primaryTitle: String
    let secondaryTitle: String
    let tertiaryTitle: String
}
```

页面状态建议：

```swift
@Observable
final class CalendarScreenModel {
    var selectedDate: Date = .now
    var visibleDates: [DayPage] = []
    var events: [CalendarEventUIModel] = []
    var fabState: FABState = .idle
    var showingTextInput = false
    var activeConversation: ConversationContext?
}
```

关键原则：
- `DatePagerView` 与 `TimelineView` 共用同一个 `selectedDate`
- split view 预览区和主页 Timeline 共用 `CalendarEventUIModel`
- 录音态只是 `fabState` 的 UI 分支，不单独开一个 screen model

---

## 4. 主日历页实现建议

### 4.1 MainCalendarScreen

推荐结构：

```swift
struct MainCalendarScreen: View {
    @State private var model = CalendarScreenModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            background

            VStack(spacing: 0) {
                CalendarHeaderView(
                    monthTitle: monthTitle,
                    onTodayTap: jumpToToday,
                    onMenuTap: openSettings
                )

                DatePagerView(
                    selectedDate: $model.selectedDate,
                    visibleDates: model.visibleDates,
                    onSelectDate: selectDate
                )

                TimelineView(
                    selectedDate: model.selectedDate,
                    events: eventsForSelectedDate,
                    currentTime: .now,
                    onEventTap: openEvent
                )
            }

            FloatingInputBar(
                fabState: model.fabState,
                onTypeTap: openTextInput,
                onPressBegan: startRecording,
                onPressEnded: stopRecording,
                onCancelRecording: cancelRecording
            )
        }
        .sheet(item: $model.activeConversation) { context in
            UnifiedConversationScreen(context: context)
        }
    }
}
```

### 4.2 DatePagerView

实现建议：
- 用横向 `ScrollView` 或 `TabView` 风格分页都可以，但交互感要接近系统日历
- 默认显示 5 天窗口，不做大卡片
- 当前日期高亮成圆形
- 前后日期只做透明度弱化，不做强容器
- 与 Timeline 横向翻页共用状态源

不建议：
- 做成轮播卡片
- 加重阴影、重边框、重动效
- 把日期区域做得比导航栏更抢视觉

### 4.3 TimelineView

实现建议：
- 垂直滚动
- 固定小时高度 `60pt`
- 使用 `GeometryReader` 或布局计算生成事件块位置
- 当前时间红线使用单独 overlay
- 录音中保持可滚动，不要用全屏蒙层挡住 Timeline

---

## 5. 统一日程对话页实现建议

`UnifiedConversationScreen` 是 V1 唯一的对话页模板，早间规划和晚间复盘都只作为内容变体。

```swift
struct UnifiedConversationScreen: View {
    let context: ConversationContext

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            SplitPreviewCard(
                title: context.previewTitle,
                badge: context.variant == .planning ? "规划建议" : "复盘建议",
                previewDate: context.previewDate,
                previewEvents: context.previewEvents,
                actions: context.actions
            )

            Divider()
                .overlay(Color.calpalBlue.frame(height: 2))

            conversationArea
        }
    }
}
```

### 5.1 变体规则

`.planning`
- 文案偏主动建议
- 预览聚焦“今天下午 / 接下来空档”
- 按钮通常为 `采纳 / 改时间 / 略过`

`.review`
- 文案偏复盘后补排
- 预览聚焦“明天早上 / 下一次补做机会”
- 按钮通常为 `采纳 / 稍后 / 忽略`

### 5.2 视觉规则

- 上半区预览沿用主页 Timeline 的事件块视觉
- 下半区只保留必要气泡，不做聊天 App 式复杂头像和消息列表
- 小型 FAB 与 `Type` 按钮保留，但弱于主页

---

## 6. Onboarding 与设置页

### 6.1 OnboardingFlowView
- 使用 `TabView` 或受控页索引实现 3 步流程
- 每一步保持单一任务，不混入过多解释
- Apple Intelligence 状态页默认展示“已启用”，同时保留“未启用”文案位

### 6.2 SettingsView
- 用 `Form` 或系统风格列表即可
- V1 只需要：
  - 语音输入语言
  - 本地 AI 状态
  - Claude API 占位入口
  - 权限与隐私说明

---

## 7. 设计令实现更顺的细节

- `CalendarTheme` 统一颜色、圆角、阴影、间距，避免散落 magic numbers
- `LayoutMetrics` 统一管理：
  - timeline hour height
  - fab size
  - split view ratio
  - safe area spacing
- `EventBlockView` 不直接依赖 EventKit；先渲染 UI model，方便预览和测试
- `UnifiedConversationScreen` 不直接依赖 AI service；通过 context 注入结果，降低页面耦合

---

## 8. 实现优先级

1. 先完成 `MainCalendarScreen` 骨架与 `DatePagerView`
2. 再完成 `TimelineView` 与事件块布局
3. 接入 `FloatingInputBar` 和录音态
4. 完成 `UnifiedConversationScreen`
5. 最后补 Onboarding / Settings

这样可以优先打通 V1 最重要的主路径：

```text
主日历 -> 录音/输入 -> 本地 AI 解析 -> 统一对话确认 -> Apple Calendar 写入
```
