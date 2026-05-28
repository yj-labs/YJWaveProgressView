# YJWaveProgressView

一款纯 Swift 实现的圆形水波进度控件，支持进度水波动画、刻度表盘、重力感应、富文本百分比和描述文案，适合电量、水位、容量、完成度等圆形进度展示场景。

<p align="center">
<a href="https://github.com/YongTaiSin/YJWaveProgressView"><img src="https://img.shields.io/badge/platform-iOS%2011.0%2B-ff69b5152950834.svg"></a>
<a href="https://github.com/YongTaiSin/YJWaveProgressView"><img src="https://img.shields.io/badge/Swift-5-orange.svg"></a>
<a href="https://github.com/YongTaiSin/YJWaveProgressView"><img src="https://img.shields.io/cocoapods/v/YJWaveProgressView.svg?style=flat"></a>
<a href="https://github.com/YongTaiSin/YJWaveProgressView/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>
</p>

## Preview

| 水波进度 | 刻度表盘 | 重力感应 |
| --- | --- | --- |
| <img src="https://github.com/YongTaiSin/YJWaveProgressView/blob/master/screenshots/%E6%B0%B4%E6%B3%A2.gif" width="220" alt="水波进度"> | <img src="https://github.com/YongTaiSin/YJWaveProgressView/blob/master/screenshots/%E5%B8%A6%E5%88%BB%E5%BA%A6.gif" width="220" alt="刻度表盘"> | <img src="https://github.com/YongTaiSin/YJWaveProgressView/blob/master/screenshots/%E9%87%8D%E5%8A%9B%E6%84%9F%E5%BA%94.gif" width="220" alt="重力感应"> |

## Requirements

- iOS 11.0+
- Swift 5.0+
- UIKit
- CoreMotion only when `allowCoreMotion` is enabled

## Installation

### CocoaPods

```ruby
pod 'YJWaveProgressView'
```

### Manual

Drag `YJWaveProgressView/YJWaveProgressView.swift` into your project.

## Quick Start

```swift
let waveView = YJWaveProgressView()
waveView.waterColor = UIColor(red: 107 / 255, green: 194 / 255, blue: 53 / 255, alpha: 1)
waveView.waterBgColor = UIColor(red: 107 / 255, green: 194 / 255, blue: 53 / 255, alpha: 0.6)
waveView.descriptionText = "汽车当前电量"
waveView.showScale = true
waveView.scaleStyle = .clock
waveView.allowCoreMotion = true
waveView.progress = 0.8

view.addSubview(waveView)
waveView.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    waveView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    waveView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    waveView.widthAnchor.constraint(equalToConstant: 300),
    waveView.heightAnchor.constraint(equalTo: waveView.widthAnchor)
])
```

`progress` 的取值范围是 `0...1`，超出范围会自动截断。

## Features

- 圆形水波进度动画
- 进度变化时的水位上升/下降动画
- 自定义波长、振幅、移动速度和上升速度
- 自定义水波颜色、背景色、文字颜色和字体
- 自定义百分比/描述富文本
- 可选刻度表盘，支持普通刻度和时钟刻度样式
- 可选 CoreMotion 重力感应，让水波跟随设备姿态倾斜
- 支持 Auto Layout

## API

### Progress

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `progress` | `CGFloat` | `0` | 进度，范围 `0...1` |
| `waveLength` | `CGFloat` | `0` | 波长。为 `0` 时根据水波宽度自动计算 |
| `amplitude` | `CGFloat` | `6` | 振幅 |
| `waveSpeed` | `CGFloat` | `8` | 波纹水平移动速度 |
| `waveGrowth` | `CGFloat` | `0.85` | 水位上升/下降速度 |

### Colors And Text

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `waterColor` | `UIColor` | 深蓝色 | 水波颜色 |
| `waterBgColor` | `UIColor` | 蓝色背景 | 水波背景色 |
| `textColor` | `UIColor` | `.white` | 文本颜色 |
| `descriptionText` | `String` | `""` | 百分比下方描述文字 |
| `descriptionFont` | `UIFont?` | `nil` | 描述文字字体 |
| `numberFont` | `UIFont?` | `nil` | 百分比数字字体 |
| `percentFont` | `UIFont?` | `nil` | `%` 字体 |
| `descriptionAttributedText` | `NSAttributedString?` | `nil` | 自定义描述富文本 |
| `percentageAttributedText` | `NSAttributedString?` | `nil` | 自定义百分比富文本 |

### Scale

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `showScale` | `Bool` | `false` | 是否显示刻度表盘 |
| `waveMargin` | `CGFloat` | `10` | 刻度到圆形水波的距离 |
| `scaleLength` | `CGFloat` | `10` | 刻度长度 |
| `scaleWidth` | `CGFloat` | `2` | 刻度宽度 |
| `scaleCount` | `Int` | `60` | 刻度数量 |
| `scaleBgColor` | `UIColor` | 浅蓝色 | 刻度背景色 |
| `scaleColor` | `UIColor` | 黄色 | 进度刻度颜色 |
| `scaleStyle` | `YJWaveScaleStyle` | `.regular` | 刻度样式，支持 `.regular` 和 `.clock` |

### Motion

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `allowCoreMotion` | `Bool` | `false` | 是否开启重力感应 |

开启重力感应后，组件会使用 `CMMotionManager` 监听设备姿态，并让水波层产生类似液体倾斜的效果。不需要时请保持关闭。

### Methods

| Method | Description |
| --- | --- |
| `startWave()` | 开始水波动画 |
| `stopWave()` | 停止水波动画，并关闭重力感应 |

设置 `progress` 时会自动调用 `startWave()`。

## Custom Text

如果默认百分比和描述样式不够用，可以直接传入富文本：

```swift
let percentage = NSMutableAttributedString(string: "80%")
percentage.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 56), range: NSRange(location: 0, length: 2))
percentage.addAttribute(.font, value: UIFont.systemFont(ofSize: 24), range: NSRange(location: 2, length: 1))
percentage.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: 3))

waveView.percentageAttributedText = percentage
waveView.descriptionAttributedText = NSAttributedString(string: "\n当前电量")
```

## Scale Style

```swift
waveView.showScale = true
waveView.scaleStyle = .regular

// or
waveView.scaleStyle = .clock
```

`.clock` 会让非 5 倍数位置的刻度更短，更接近表盘样式。

## Migration From 1.x

`2.0.0` 起组件改为纯 Swift，不再保留 Objective-C API 兼容层。

主要变化：

- 删除 `YJWaveProgressView.h` / `YJWaveProgressView.m`
- 新增 `YJWaveProgressView.swift`
- `YJWaveScaleStyle_Default` 改为 `.regular`
- `YJWaveScaleStyle_Clock` 改为 `.clock`
- 最低系统版本从 iOS 8.0 调整为 iOS 11.0

## Example

仓库内包含 `YJWaveProgressViewExample.xcodeproj`，打开后运行 `YJWaveProgressViewExample` scheme 即可查看示例。

当前使用 Xcode 26.2 构建 iOS 11 deployment target 时，模拟器构建可能会提示 Xcode 支持范围从 iOS 12 开始。这是 Xcode 版本提示，不影响组件在 iOS 11+ 项目中使用。

## Release Notes

- **2.0.0**
  - 使用 Swift 重写组件
  - 示例工程迁移到 Swift
  - 最低支持版本调整为 iOS 11.0
  - 移除 Objective-C API 兼容
- **1.1.0**
  - 新增刻度盘显示
  - 支持重力感应

## Contact

- Email: jellybilly@foxmail.com

## License

YJWaveProgressView is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
