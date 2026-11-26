# LingoLearn - iOS 背单词应用

### 🔥🔥🔥对于视频1：https://youtu.be/_h2MGwJO1Yc
### 🔥🔥🔥对于视频2：https://youtu.be/T8nQSFXvoLA


一款功能完整的 iOS 背单词应用，采用 SwiftUI + SwiftData 构建，支持 SM-2 间隔重复算法。

## 功能特性

### 首页
- 环形进度条显示今日学习进度
- 连续打卡天数统计
- 待复习单词数量提醒
- 快捷按钮：开始学习、快速复习、随机测试

### 单词学习
- 3D 翻转卡片动画
- 滑动手势：右滑(认识)、左滑(不认识)、上滑(收藏)
- 系统 TTS 发音
- SM-2 算法自动安排复习计划
- 学习结束统计弹窗

### 练习测试
- 选择题：显示单词，四选一中文释义
- 填空题：显示中文，输入英文单词
- 听力题：播放发音，选择正确单词
- 倒计时进度条
- 答题动画反馈

### 学习进度
- 折线图展示近 7/30 天学习趋势
- GitHub 风格日历热力图
- 掌握度分布饼图
- 成就徽章墙

### 设置
- 每日学习目标 (10-100 个)
- 学习提醒
- 音效/震动反馈开关
- 外观模式切换

## 技术栈

- **平台**: iOS 26.0+
- **语言**: Swift 5.9
- **UI 框架**: SwiftUI
- **数据持久化**: SwiftData
- **图表**: Swift Charts
- **算法**: SM-2 间隔重复

## 项目结构

```
LingoLearn/
├── Models/              # SwiftData 数据模型
├── Core/
│   ├── Theme/           # 颜色、字体定义
│   ├── Extensions/      # 扩展方法
│   ├── Utilities/       # 工具类
│   └── Components/      # 通用 UI 组件
├── Services/            # 业务服务层
├── Features/
│   ├── Home/            # 首页
│   ├── Learning/        # 单词学习
│   ├── Practice/        # 练习测试
│   ├── Progress/        # 学习进度
│   └── Settings/        # 设置
└── Resources/Words/     # 词汇数据 (500+ CET4/CET6)
```

## 运行项目

1. 使用 Xcode 16+ 打开 `LingoLearn.xcodeproj`
2. 选择目标设备 (iPhone 模拟器)
3. 点击运行 (⌘+R)

## 设计规范

- 主色调: #0EA5E9 (蓝色)
- 辅助色: #14B8A6 (青绿色)
- 支持浅色/深色模式
- 全局触觉反馈

## 许可证

MIT License
