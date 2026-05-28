//
//  ViewController.swift
//  YJWaveProgressViewExample
//
//  Created by Jeremiah on 2018/11/29.
//

import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.165, green: 0.659, blue: 0.980, alpha: 1)

        let size: CGFloat = 300
        let waveView = YJWaveProgressView(frame: CGRect(
            x: (view.bounds.width - size) / 2,
            y: 0,
            width: size,
            height: size
        ))
        waveView.center = view.center
        waveView.waterColor = UIColor(red: 107 / 255, green: 194 / 255, blue: 53 / 255, alpha: 1)
        waveView.waterBgColor = UIColor(red: 107 / 255, green: 194 / 255, blue: 53 / 255, alpha: 0.6)
        waveView.descriptionText = "汽车当前电量"
        waveView.showScale = true
        waveView.scaleStyle = .clock
        waveView.allowCoreMotion = true
        waveView.progress = 0.6

        view.addSubview(waveView)
    }
}
