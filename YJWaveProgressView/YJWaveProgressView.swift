//
//  YJWaveProgressView.swift
//  YJWaveProgressView
//
//  Created by Jeremiah on 2018/11/28.
//
/*
 正弦型函数解析式：y=Asin（ωx+φ）+h
 各常数值对函数图像的影响：
 φ（初相位）：决定波形与X轴位置关系或横向移动距离（左加右减）
 ω：决定周期（最小正周期T=2π/|ω|）
 A：决定峰值（即纵向拉伸压缩的倍数）
 h：表示波形在Y轴的位置关系或纵向移动距离（上加下减）

 如果想绘制出来一条正弦函数曲线，可以沿着假想的曲线绘制许多个点，然后把点逐一用直线连在一起，如果点足够多，就可以得到一条满足需求的曲线，这也是一种微分的思想。而这些点的位置可以通过正弦函数的解析式求得。
 假如水波的峰值是1，周期是2π，初相位是0，h位移也是0。那么计算各个点的坐标公式就是y = sin(x);获得各个点的坐标之后，使用addLine这个方法，把这些点逐一连成线，就可以得到最后的路径。

 如果想要得到一个动态的波纹，随着时间的变化，我们如果假定每个点的x位置没有变化，那么只要让其y随着时间有规律的变化就可以让人觉得是在有规律的动。需要注意UIKit的坐标系统y轴是向下延伸。
 如果想在0到2π这个距离显示2个完整的波曲线，那么周期就是π。如果每次增加π/4，则4s就会完成一个周期。
 如果想要在width宽度上展示2个周期的水波，则周期是waveWidth / 2, ω = 2 * .pi / T
*/

import CoreMotion
import UIKit

public enum YJWaveScaleStyle {
    /// 默认
    case regular
    /// 时钟
    case clock
}

open class YJWaveProgressView: UIView {
    /// 进度 (0 ~ 1)
    public var progress: CGFloat = 0 {
        didSet {
            progress = Self.clampedProgress(progress)
            startWave()
            drawText()
            animateScale(from: Self.clampedProgress(oldValue), to: progress)
        }
    }

    /// 波长，默认会根据水波宽度自动计算
    public var waveLength: CGFloat = 0 {
        didSet { redraw() }
    }

    /// 振幅 默认为6
    public var amplitude: CGFloat = 6 {
        didSet { redraw() }
    }

    /// 波纹移动速度 默认为8
    public var waveSpeed: CGFloat = 8
    /// 波纹上升速度 默认为0.85
    public var waveGrowth: CGFloat = 0.85

    /// 水波颜色
    public var waterColor: UIColor = UIColor(red: 0.325, green: 0.392, blue: 0.729, alpha: 1) {
        didSet {
            waveLayer.fillColor = waterColor.cgColor
        }
    }

    /// 水波的背景色
    public var waterBgColor: UIColor = UIColor(red: 0.259, green: 0.329, blue: 0.506, alpha: 1) {
        didSet {
            waveBackLayer.fillColor = waterBgColor.cgColor
        }
    }

    /// 文字颜色
    public var textColor: UIColor = .white {
        didSet { drawText() }
    }

    /// 描述文字
    public var descriptionText: String = "" {
        didSet { drawText() }
    }

    /// 描述文字字体
    public var descriptionFont: UIFont? {
        didSet { drawText() }
    }

    /// 数字字体
    public var numberFont: UIFont? {
        didSet { drawText() }
    }

    /// 百分比字体
    public var percentFont: UIFont? {
        didSet { drawText() }
    }

    /// 描述属性文字
    public var descriptionAttributedText: NSAttributedString? {
        didSet { drawText() }
    }

    /// 百分比属性文本
    public var percentageAttributedText: NSAttributedString? {
        didSet { drawText() }
    }

    /// 是否显示刻度表盘 默认为false
    public var showScale = false {
        didSet {
            setNeedsLayout()
            redraw()
        }
    }

    /// 刻度到圆形水波的距离 默认为10
    public var waveMargin: CGFloat = 10 {
        didSet {
            setNeedsLayout()
            redraw()
        }
    }

    /// 刻度长度 默认为10
    public var scaleLength: CGFloat = 10 {
        didSet {
            scaleLeftMaskLayer.lineWidth = scaleLength
            scaleRightMaskLayer.lineWidth = scaleLength
            setNeedsLayout()
            redraw()
        }
    }

    /// 刻度宽度 默认为2
    public var scaleWidth: CGFloat = 2 {
        didSet { redraw() }
    }

    /// 刻度的个数 默认为60
    public var scaleCount: Int = 60 {
        didSet { redraw() }
    }

    /// 刻度线背景色
    public var scaleBgColor: UIColor = UIColor(red: 0.694, green: 0.745, blue: 0.867, alpha: 1) {
        didSet { redraw() }
    }

    /// 刻度线颜色
    public var scaleColor: UIColor = UIColor(red: 0.969, green: 0.937, blue: 0.227, alpha: 1) {
        didSet { redraw() }
    }

    /// 刻度的样式
    public var scaleStyle: YJWaveScaleStyle = .regular {
        didSet { redraw() }
    }

    /// 是否允许重力感应 默认为false
    public var allowCoreMotion = false {
        didSet {
            allowCoreMotion ? startGravity() : stopGravity()
        }
    }

    /// 视图frame
    private var fullRect = CGRect.zero
    /// 刻度frame
    private var scaleRect = CGRect.zero
    /// 水波frame
    private var waveRect = CGRect.zero

    /// 当前百分比，用于保存第一次显示时的动画效果
    private var currentPercent: CGFloat = 0
    /// 当前波浪上升高度Y（高度从大到小 坐标系向下增长）
    private var currentWavePointY: CGFloat = 0
    /// 波浪x位移
    private var offsetX: CGFloat = 0
    /// 可变参数，更加真实地模拟波纹
    private var variable: CGFloat = 1.6
    /// 增减变化
    private var isIncreasing = false
    private var baseWaveTransform = CGAffineTransform.identity
    /// 最新偏航角
    private var motionLastYaw: CGFloat = 0
    /// estimated error
    private var motionEstimatedError: CGFloat = 0.1
    /// kalman filter gain
    private var motionFilterGain: CGFloat = 0.5

    /// 刷新定时器
    private var displayLink: CADisplayLink?
    private var displayLinkProxy: DisplayLinkProxy?
    /// 重力感应管理
    private lazy var motionManager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 0.02
        return manager
    }()

    /// 水波背景层
    private lazy var waveBackLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = waterBgColor.cgColor
        return layer
    }()

    /// 水波层
    private lazy var waveLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = waterColor.cgColor
        return layer
    }()

    /// 刻度背景层
    private let scaleBackLayer = CAShapeLayer()
    /// 刻度层
    private let scaleLayer = CAShapeLayer()

    /// 左边刻度
    private lazy var scaleLeftLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.mask = scaleLeftMaskLayer
        return layer
    }()

    /// 右边刻度
    private lazy var scaleRightLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.mask = scaleRightMaskLayer
        return layer
    }()

    /// 左边刻度遮罩
    private lazy var scaleLeftMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = scaleLength
        layer.strokeColor = UIColor.red.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeStart = 0
        layer.strokeEnd = 0
        return layer
    }()

    /// 右边刻度遮罩
    private lazy var scaleRightMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = scaleLength
        layer.strokeColor = UIColor.red.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeStart = 0
        layer.strokeEnd = 0
        return layer
    }()

    /// 文字
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    // MARK: - init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    deinit {
        stopWave()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        configureDrawingRects()
        if currentWavePointY == 0 || currentWavePointY > waveRect.height {
            currentWavePointY = waveRect.height
        }

        // 水波
        waveBackLayer.frame = waveRect
        waveLayer.frame = waveBackLayer.bounds
        baseWaveTransform = waveLayer.affineTransform()

        // 文本
        textLabel.frame = waveRect

        // 刻度
        scaleBackLayer.frame = scaleRect
        scaleLayer.frame = scaleRect
        scaleLeftLayer.frame = CGRect(x: 0, y: 0, width: scaleRect.width / 2, height: scaleRect.height)
        scaleRightLayer.frame = CGRect(x: scaleRect.width / 2, y: 0, width: scaleRect.width / 2, height: scaleRect.height)

        redraw()
    }

    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawBezierPath()
    }

    /// 开始波动
    public func startWave() {
        if displayLink?.isPaused == false {
            return
        }

        // 以屏幕刷新速度为周期刷新曲线的位置
        let proxy = DisplayLinkProxy { [weak self] displayLink in
            self?.updateWave(displayLink)
        }
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.update(_:)))
        link.add(to: .main, forMode: .common)
        displayLinkProxy = proxy
        displayLink = link

        if allowCoreMotion {
            // 允许重力感应
            startGravity()
        }
    }

    /// 停止波动
    public func stopWave() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
        stopGravity()
    }

    private func configure() {
        backgroundColor = .clear

        // 初始化绘制区域
        configureDrawingRects()

        // 添加刻度背景层
        layer.addSublayer(scaleBackLayer)
        // 添加刻度层
        layer.addSublayer(scaleLayer)
        scaleLayer.addSublayer(scaleLeftLayer)
        scaleLayer.addSublayer(scaleRightLayer)

        // 添加背景层
        layer.addSublayer(waveBackLayer)
        // 添加水波层
        waveBackLayer.addSublayer(waveLayer)

        // 添加文本
        addSubview(textLabel)
    }

    private func configureDrawingRects() {
        let size = min(bounds.width, bounds.height)
        let x = (bounds.width - size) / 2
        let y = (bounds.height - size) / 2

        fullRect = CGRect(x: x, y: y, width: size, height: size)
        scaleRect = fullRect

        let offset = showScale ? waveMargin + scaleLength : 0
        waveRect = fullRect.insetBy(dx: offset, dy: offset)
    }

    // MARK: - wave

    /// 动态更新水波
    @objc private func updateWave(_ displayLink: CADisplayLink) {
        animateWave()
        updateWaveY()
        drawWave()
    }

    /// 动态改变波形参数
    private func animateWave() {
        if isIncreasing {
            variable += 0.01
        } else {
            variable -= 0.01
        }

        if variable <= 1 {
            isIncreasing = true
        }

        if variable >= 1.6 {
            isIncreasing = false
        }

        offsetX += waveSpeed
    }

    /// 更新Y轴偏距的大小，直到达到目标偏距，让wave有一个匀速增长的效果
    private func updateWaveY() {
        guard waveRect.height > 0 else { return }

        let targetY = waveRect.height - progress * waveRect.height
        if currentWavePointY < targetY {
            currentWavePointY = min(currentWavePointY + waveGrowth, waveRect.height)
        }

        if currentWavePointY > targetY {
            currentWavePointY = max(currentWavePointY - waveGrowth, 0)
        }
    }

    // MARK: - motion

    private func startGravity() {
        stopGravity()
        guard motionManager.isDeviceMotionAvailable else { return }

        // to avoid using more CPU than necessary we use ``CMAttitudeReferenceFrameXArbitraryZVertical``
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] _, _ in
            self?.motionRefresh()
        }
    }

    private func stopGravity() {
        motionLastYaw = 0
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }

    private func motionRefresh() {
        guard let attitude = motionManager.deviceMotion?.attitude else { return }

        // compute the device yaw from the attitude quaternion
        // http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
        let quaternion = attitude.quaternion
        var yaw = CGFloat(asin(2 * (quaternion.x * quaternion.z - quaternion.w * quaternion.y)))

        // TODO improve the yaw interval (stuck to [-PI/2, PI/2] due to arcsin definition
        // reverse the angle so that it reflect a liquid-like behavior
        yaw *= -1

        if motionLastYaw == 0 {
            motionLastYaw = yaw
        }

        // 空间位置的四元数
        // kalman filtering
        let q: CGFloat = 0.1   // process noise
        let s: CGFloat = 0.1   // sensor noise

        var x = motionLastYaw
        motionEstimatedError += q
        motionFilterGain = motionEstimatedError / (motionEstimatedError + s)
        x += motionFilterGain * (yaw - x)
        motionEstimatedError = (1 - motionFilterGain) * motionEstimatedError

        let newTransform = baseWaveTransform.rotated(by: -x)
        waveLayer.setAffineTransform(newTransform)
        motionLastYaw = x
    }

    // MARK: - private methods

    /// 格式化电量的Label的字体
    ///
    /// - Parameter percent: 百分比
    /// - Returns: 电量百分比属性文本
    private func formattedPercentage(_ percent: Int) -> NSMutableAttributedString {
        let percentText = "\(percent)%"
        let attributedText = NSMutableAttributedString(string: percentText)

        var numberFontSize: CGFloat = 60
        var percentFontSize: CGFloat = 30
        if waveRect.width < 180 {
            let ratio = max(waveRect.width / 180, 0)
            numberFontSize *= ratio
            percentFontSize *= ratio
        }

        let capacityNumberFont = numberFont ?? UIFont(name: "HelveticaNeue-Thin", size: numberFontSize) ?? .systemFont(ofSize: numberFontSize, weight: .thin)
        let capacityPercentFont = percentFont ?? UIFont(name: "HelveticaNeue-Thin", size: percentFontSize) ?? .systemFont(ofSize: percentFontSize, weight: .thin)

        let nsText = percentText as NSString
        let numberRange = nsText.range(of: "\(percent)")
        let percentRange = nsText.range(of: "%")
        attributedText.addAttribute(.font, value: capacityNumberFont, range: numberRange)
        attributedText.addAttribute(.font, value: capacityPercentFont, range: percentRange)
        attributedText.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: nsText.length))

        return attributedText
    }

    /// 格式化描述Label的字体
    ///
    /// - Parameter descriptionText: 描述文字
    /// - Returns: 描述属性文本
    private func formattedDescription(_ descriptionText: String) -> NSMutableAttributedString {
        var descriptionFontSize: CGFloat = 14
        if waveRect.width < 150 {
            descriptionFontSize *= max(waveRect.width / 150, 0)
        }

        let font = descriptionFont ?? UIFont.systemFont(ofSize: descriptionFontSize)
        let attributedText = NSMutableAttributedString(string: descriptionText)
        let fullRange = NSRange(location: 0, length: (descriptionText as NSString).length)
        attributedText.addAttribute(.font, value: font, range: fullRange)
        attributedText.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        return attributedText
    }

    // MARK: - draw

    private func drawBezierPath() {
        if showScale {
            drawScaleBackground()
            drawScale()
        } else {
            scaleBackLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            scaleLeftLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
            scaleRightLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        }

        drawWaveBackground()
        drawWave()
        drawText()
    }

    /// 画刻度盘
    ///
    /// - Parameters:
    ///   - scaleColor: 刻度颜色
    ///   - isLeft: 是否是左边的刻度盘
    /// - Returns: 刻度layer数组
    private func drawScale(with scaleColor: UIColor, isLeft: Bool) -> [CAShapeLayer] {
        let section = max(scaleCount / 2, 1)
        let count = section + 1
        let perAngle = CGFloat.pi / CGFloat(section)
        var centerPoint = CGPoint(x: scaleRect.width / 2, y: scaleRect.height / 2)
        if !isLeft {
            // 右边的圆心坐标
            centerPoint = CGPoint(x: 0, y: scaleRect.height / 2)
        }

        let radius = max((scaleRect.width - scaleLength) / 2, 0.1)
        var scaleLayers: [CAShapeLayer] = []

        // 我们需要计算出每段弧线的起始角度和结束角度
        // 角(弧度) = 弧长/半径
        for index in 0 ..< count {
            let i = CGFloat(index)
            let isEndpoint = index == 0 || index == count - 1

            var startAngle: CGFloat
            if isLeft {
                startAngle = .pi / 2 + perAngle * i
                if index == count - 1 {
                    startAngle -= (scaleWidth / 2) / radius
                }
            } else {
                startAngle = .pi / 2 - perAngle * i
                if index == count - 1 {
                    startAngle += (scaleWidth / 2) / radius
                }
            }

            var endAngle: CGFloat
            if isLeft {
                endAngle = startAngle + scaleWidth / radius
                if isEndpoint {
                    endAngle = startAngle + (scaleWidth / 2) / radius
                }
            } else {
                endAngle = startAngle - scaleWidth / radius
                if isEndpoint {
                    endAngle = startAngle - (scaleWidth / 2) / radius
                }
            }

            let tickPath = UIBezierPath(
                arcCenter: centerPoint,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: isLeft
            )

            let layer = CAShapeLayer()
            layer.strokeColor = scaleColor.cgColor
            layer.lineWidth = scaleStyle == .clock && index % 5 != 0 ? scaleLength / 2 : scaleLength
            layer.path = tickPath.cgPath
            scaleLayers.append(layer)
        }

        return scaleLayers
    }

    /// 画刻度背景
    private func drawScaleBackground() {
        scaleBackLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let leftLayer = CALayer()
        leftLayer.frame = CGRect(x: 0, y: 0, width: scaleRect.width / 2, height: scaleRect.height)
        // 画左边的刻度盘
        leftLayer.sublayers = drawScale(with: scaleBgColor, isLeft: true)
        scaleBackLayer.addSublayer(leftLayer)

        let rightLayer = CALayer()
        rightLayer.frame = CGRect(x: scaleRect.width / 2, y: 0, width: scaleRect.width / 2, height: scaleRect.height)
        // 画右边的刻度盘
        rightLayer.sublayers = drawScale(with: scaleBgColor, isLeft: false)
        scaleBackLayer.addSublayer(rightLayer)
    }

    /// 画刻度
    private func drawScale() {
        scaleLeftLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        scaleRightLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 画左边的刻度盘
        scaleLeftLayer.sublayers = drawScale(with: scaleColor, isLeft: true)
        // 画右边的刻度盘
        scaleRightLayer.sublayers = drawScale(with: scaleColor, isLeft: false)

        // 左边的圆心坐标
        let leftCenterPoint = CGPoint(x: scaleRect.width / 2, y: scaleRect.height / 2)
        // 右边的圆心坐标
        let rightCenterPoint = CGPoint(x: 0, y: scaleRect.height / 2)
        let radius = max((scaleRect.width - scaleLength) / 2, 0.1)

        let leftPath = UIBezierPath(
            arcCenter: leftCenterPoint,
            radius: radius,
            startAngle: .pi / 2,
            endAngle: -.pi / 2,
            clockwise: true
        )
        scaleLeftMaskLayer.path = leftPath.cgPath

        let rightPath = UIBezierPath(
            arcCenter: rightCenterPoint,
            radius: radius,
            startAngle: .pi / 2,
            endAngle: -.pi / 2,
            clockwise: false
        )
        scaleRightMaskLayer.path = rightPath.cgPath
    }

    /// 画水波背景
    private func drawWaveBackground() {
        // 画背景圆
        let centerPoint = CGPoint(x: waveRect.width / 2, y: waveRect.height / 2)
        let radius = waveRect.width / 2
        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        waveBackLayer.path = path.cgPath
    }

    /// 画波浪
    private func drawWave() {
        guard waveRect.width > 0, waveRect.height > 0 else { return }

        var amplitude = amplitude
        if currentWavePointY <= 0 || currentWavePointY == waveRect.height {
            amplitude = 0
        }

        // 画圆形mask
        let centerPoint = CGPoint(x: waveRect.width / 2, y: waveRect.height / 2)
        let radius = waveRect.width / 2
        let maskPath = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        let mask = CAShapeLayer()
        mask.path = maskPath.cgPath
        waveLayer.mask = mask

        let effectiveWaveLength = resolvedWaveLength(radius: radius)
        let wavePath = CGMutablePath()
        let waterWaveWidth = waveRect.width

        // 画水
        wavePath.move(to: CGPoint(x: 0, y: currentWavePointY))

        var x: CGFloat = 0
        while x <= waterWaveWidth {
            let y = variable * amplitude * sin((2 * .pi / effectiveWaveLength) * x - offsetX * .pi / 180) + currentWavePointY
            wavePath.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }

        wavePath.addLine(to: CGPoint(x: waterWaveWidth, y: waveRect.height))
        wavePath.addLine(to: CGPoint(x: 0, y: waveRect.height))
        wavePath.closeSubpath()

        waveLayer.path = wavePath
    }

    /// 根据当前水位自动计算波长
    private func resolvedWaveLength(radius: CGFloat) -> CGFloat {
        guard waveLength == 0 else {
            return max(waveLength, 1)
        }

        let distanceToOrigin = abs(currentWavePointY - radius)
        let minDistanceToOrigin = abs(waveRect.height * 0.2 - radius)
        let minWidth = chordWidth(radius: radius, distance: minDistanceToOrigin)
        let width = chordWidth(radius: radius, distance: distanceToOrigin)

        return max(minWidth, width, 1)
    }

    private func chordWidth(radius: CGFloat, distance: CGFloat) -> CGFloat {
        let value = max(pow(radius, 2) - pow(distance, 2), 0)
        return 4 * sqrt(value)
    }

    /// 绘制文本
    private func drawText() {
        let attributedText = NSMutableAttributedString()

        if let percentageAttributedText, percentageAttributedText.length > 0 {
            attributedText.append(percentageAttributedText)
        } else {
            attributedText.append(formattedPercentage(Int(progress * 100)))
        }

        if let descriptionAttributedText, descriptionAttributedText.length > 0 {
            attributedText.append(descriptionAttributedText)
        } else if !descriptionText.isEmpty {
            attributedText.append(formattedDescription("\n\(descriptionText)"))
        }

        textLabel.attributedText = attributedText
    }

    /// 刻度动画
    private func animateScale(from oldProgress: CGFloat, to newProgress: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }

            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = 3
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animation.fromValue = oldProgress
            animation.toValue = newProgress
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false

            currentPercent = newProgress
            scaleLeftMaskLayer.add(animation, forKey: "strokeEndAnimation")
            scaleRightMaskLayer.add(animation, forKey: "strokeEndAnimation")
        }
    }

    private func redraw() {
        setNeedsDisplay()
        guard bounds.width > 0, bounds.height > 0 else { return }
        drawBezierPath()
    }

    private static func clampedProgress(_ progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }
}

private final class DisplayLinkProxy: NSObject {
    fileprivate var handler: (CADisplayLink) -> Void

    init(handler: @escaping (CADisplayLink) -> Void) {
        self.handler = handler
    }

    @objc func update(_ displayLink: CADisplayLink) {
        handler(displayLink)
    }
}
