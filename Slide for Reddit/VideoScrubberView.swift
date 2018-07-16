//
//  VideoScrubberView.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/13/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import CoreMedia
import Anchorage

protocol VideoScrubberViewDelegate {
    func sliderValueChanged(toSeconds: Float)
    func sliderDidBeginDragging()
    func sliderDidEndDragging()
    func toggleReturnPlaying() -> Bool
}

//extension UISlider {
//    var thumbCenterX: CGFloat {
//        let trackRect = self.trackRect(forBounds: frame)
//        let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)
//        return thumbRect.midX
//    }
//}

extension UIImage {
    class func image(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!

        context.setFillColor(color.cgColor)
        context.fill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
}

class VideoScrubberView: UIView {

    var delegate: VideoScrubberViewDelegate?
    var totalDuration: CMTime = CMTime()
    private var elapsedDuration: CMTime = CMTime()

    var slider: ThickSlider = ThickSlider()
    var timeElapsedLabel = UILabel()
    var timeTotalLabel = UILabel()

    var timeElapsedRightConstraint: NSLayoutConstraint?

    var playButton = UIButton(type: .system)
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 12)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        slider.tintColor = ColorUtil.accentColorForSub(sub: "")
//        slider.setThumbImage(UIImage(named: "circle")?.getCopy(withSize: .square(size: 72), withColor: slider.tintColor), for: .normal)
        slider.minimumValue = 0
        slider.maximumValue = 1
//        slider.isContinuous = true
//        slider.setThumbImage(UIImage(), for: .normal)
//        slider.setMinimumTrackImage(UIImage.image(with: slider.tintColor).getCopy(withSize: .square(size: 72)), for: .normal)
//        slider.setMaximumTrackImage(UIImage.image(with: slider.tintColor.withAlphaComponent(0.4)).getCopy(withSize: .square(size: 72)), for: .normal)
//        slider.thumbTintColor = ColorUtil.accentColorForSub(sub: "")
        slider.minimumTrackTintColor = ColorUtil.accentColorForSub(sub: "")
        slider.maximumTrackTintColor = ColorUtil.accentColorForSub(sub: "").withAlphaComponent(0.4)
        slider.setThumbImage(UIImage.init(named: "circle")?.getCopy(withColor: .white), for: .normal)
        self.addSubview(slider)

        self.addSubview(playButton)
        self.addSubview(timeTotalLabel)
        slider.verticalAnchors == self.verticalAnchors
        slider.leftAnchor == playButton.rightAnchor + 8
        slider.bottomAnchor == self.bottomAnchor - 8
        slider.rightAnchor == timeTotalLabel.leftAnchor - 8
        
        //timeElapsedLabel.font = UIFont.boldSystemFont(ofSize: 12)
        //timeElapsedLabel.textAlignment = .center
        //timeElapsedLabel.textColor = UIColor.white
        //self.addSubview(timeElapsedLabel)

        //timeElapsedLabel.centerYAnchor == slider.centerYAnchor
        //timeElapsedLabel.leftAnchor >= slider.leftAnchor ~ .high
//        timeElapsedRightConstraint = timeElapsedLabel.rightAnchor == CGFloat(slider.thumbCenterX - 16) ~ .low
//        slider

        timeTotalLabel.font = UIFont.boldSystemFont(ofSize: 12)
        timeTotalLabel.textAlignment = .center
        timeTotalLabel.textColor = UIColor.white

        timeTotalLabel.centerYAnchor == self.centerYAnchor
        timeTotalLabel.rightAnchor == self.rightAnchor - 16

        playButton.setImage(UIImage.init(named: "pause"), for: .normal)
        playButton.tintColor = UIColor.white
        playButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)

        playButton.sizeAnchors == .square(size: 24)
        playButton.leftAnchor == self.leftAnchor + 16
        playButton.centerYAnchor == self.centerYAnchor

        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderDidBeginDragging(_:)), for: .editingDidBegin)
        slider.addTarget(self, action: #selector(sliderDidEndDragging(_:)), for: [.touchUpInside,.touchUpOutside])
    }
    
    func updateWithTime(elapsedTime: CMTime) {
        if CMTIME_IS_INVALID(elapsedTime) {
            slider.minimumValue = 0.0
            return
        }
        elapsedDuration = elapsedTime
        let duration = Float(CMTimeGetSeconds(totalDuration))
        let time = Float(CMTimeGetSeconds(elapsedTime))
        if duration.isFinite && duration > 0 {
            slider.minimumValue = 0.0
            slider.maximumValue = duration
            slider.setValue(time, animated: true)
            timeElapsedLabel.text = getTimeString(time)
            timeTotalLabel.text = "-\(getTimeString(1 + duration - time))"
        }
    }

    private func getTimeString(_ time: Float) -> String {
        let totalTime = Int(floor(time))
        var minutes = Double(totalTime) / 60
        let seconds = totalTime % 60
        if(totalTime < 60){
            minutes = 0
        }

        return String(format:"%02d:%02d", minutes, seconds)
    }

}

extension VideoScrubberView {
    func sliderValueChanged(_ sender: ThickSlider) {
        delegate?.sliderValueChanged(toSeconds: sender.value)
    }

    func sliderDidBeginDragging(_ sender: ThickSlider) {
        delegate?.sliderDidBeginDragging()
    }

    func sliderDidEndDragging(_ sender: ThickSlider) {
        delegate?.sliderDidEndDragging()
    }

    func playButtonTapped(_ sender: UIButton) {
        if let delegate = delegate {
            if(delegate.toggleReturnPlaying()){
                playButton.setImage(UIImage.init(named: "pause"), for: .normal)
            } else {
                playButton.setImage(UIImage.init(named: "play"), for: .normal)
            }
        }
    }
}

public class ThickSlider : UISlider {
    override public func trackRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.trackRect(forBounds: bounds)
        result.size.height = 8
        return result
    }
}
