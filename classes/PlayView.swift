//
//  PlayView.swift
//  mdxplayer
//
//  Created by asada on 2016/08/27.
//  Copyright asada. All rights reserved.
//

import UIKit

class PlayView: UIView, PlayerDelegate {

	let keyLayer = CALayer()
	let speLayer = CALayer()
	let spmaskLayer = CALayer()
	let borderLayer = CALayer()

	let playBtn = UIButton.imageButton(UIImage(named: "pause"), frame: CGRect(0, 0, 44, 44))
	let prevBtn = UIButton.imageButton(UIImage(named: "rewind"), frame: CGRect(0, 0, 44, 44))
	let nextBtn = UIButton.imageButton(UIImage(named: "forward"), frame: CGRect(0, 0, 44, 44))

	let openBtn = UIButton.imageButton(UIImage(named: "arrow_up"), frame: CGRect(0, 0, 44, 44))

	let svoliv = UIImageView(image: UIImage(named: "volume_down"))
	let mvoliv = UIImageView(image: UIImage(named: "volume_up"))

	let smpBtn = UIButton.imageButton(UIImage(named: "hzback"), frame: CGRect(0, 0, 44, 44))
	let loopBtn = UIButton.imageButton(UIImage(named: "repeatback"), frame: CGRect(0, 0, 44, 44))

	let smpLabel = UILabel()
	let loopLabel = UILabel()

	let closeBtn = UIButton()

	let progressSlider = UISlider()
	let volSlider = UISlider()

	let titleLabel = UILabel()
	let descLabel = UILabel()

	let progressLabel = UILabel()
	let durationLabel = UILabel()

	var opened: Bool = false

	override init(frame: CGRect) {
		super.init(frame: frame)
		tintColor = UIColor.mdxColor

		let iv = UIImageView(image: UIImage(named: "wallpaper"))
		iv.contentMode = .ScaleAspectFill
		iv.clipsToBounds = true
		iv.frame = bounds
		iv.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		addSubview(iv)

		Player.sharedInstance().delegate = self

		addSubview(openBtn)
		addSubview(playBtn)
		addSubview(prevBtn)
		addSubview(nextBtn)

		addSubview(volSlider)
		addSubview(svoliv)
		addSubview(mvoliv)

		addSubview(progressSlider)
		addSubview(progressLabel)
		addSubview(durationLabel)

		addSubview(titleLabel)
		addSubview(descLabel)

		addSubview(smpBtn)
		addSubview(loopBtn)

		smpBtn.addSubview(smpLabel)
		smpLabel.frame = smpBtn.bounds
		smpLabel.textAlignment = .Center
		smpLabel.font = UIFont.systemFontOfSize(9)
		smpLabel.text = "44.1k"
		smpLabel.textColor = UIColor.blackColor()

		loopBtn.addSubview(loopLabel)
		loopLabel.frame = loopBtn.bounds
		loopLabel.textAlignment = .Center
		loopLabel.font = UIFont.systemFontOfSize(10)
		loopLabel.text = "1"
		loopLabel.textColor = UIColor.mdxColor

		titleLabel.textAlignment = .Center
		titleLabel.font = UIFont(name: "KH-Dot-Kodenmachou-16-Ki", size: 16)
		titleLabel.textColor = UIColor.whiteColor()
		titleLabel.numberOfLines = 3

		descLabel.textAlignment = .Center
		descLabel.font = UIFont.systemFontOfSize(12)
		descLabel.textColor = UIColor.lightGrayColor()

		progressLabel.textColor = UIColor.lightGrayColor()
		progressLabel.font = UIFont.systemFontOfSize(12)
		progressLabel.textAlignment = .Left

		durationLabel.textColor = UIColor.lightGrayColor()
		durationLabel.font = UIFont.systemFontOfSize(12)
		durationLabel.textAlignment = .Right

		progressSlider.setThumbImage(UIImage(), forState: .Normal)
		progressSlider.maximumTrackTintColor = UIColor(white: 0, alpha: 0.2)

		volSlider.setThumbImage(UIImage(named: "volume_thumb"), forState: .Normal)

		openBtn.addTarget(self, action: #selector(tapArrow(_:)), forControlEvents: .TouchUpInside)

		playBtn.setImage(UIImage(named: "play"), forState: .Selected)
		playBtn.addTarget(self, action: #selector(tapPlay), forControlEvents: .TouchUpInside)

		prevBtn.addTarget(self, action: #selector(tapPrev), forControlEvents: .TouchUpInside)
		nextBtn.addTarget(self, action: #selector(tapNext), forControlEvents: .TouchUpInside)

		smpBtn.addTarget(self, action: #selector(tapSmp), forControlEvents: .TouchUpInside)
		loopBtn.addTarget(self, action: #selector(tapLoop), forControlEvents: .TouchUpInside)

		keyLayer.magnificationFilter = kCAFilterNearest
		speLayer.magnificationFilter = kCAFilterNearest
		spmaskLayer.magnificationFilter = kCAFilterNearest

		Player.prepareMask(spmaskLayer)

		layer.addSublayer(keyLayer)
		layer.addSublayer(speLayer)
		speLayer.addSublayer(spmaskLayer)
		Player.redrawKey(keyLayer, speana: speLayer, paint: false)

		Player.sharedInstance().volume = 1
		volSlider.value = Player.sharedInstance().volume
		volSlider.addTarget(self, action: #selector(changeVolume), forControlEvents: .ValueChanged)

		loopLabel.text = "\( Player.sharedInstance().loopCount )"
		smpLabel.text = String(format: "%.1fk", Float(Player.sharedInstance().samplingRate) / 1000)

		borderLayer.backgroundColor = UIColor(white: 200 / 255, alpha: 1).CGColor
		borderLayer.frame = CGRect(0, 0, width, 1)
		layer.addSublayer(borderLayer)

		let uges = UISwipeGestureRecognizer(target: self, action: #selector(doOpen))
		uges.direction = .Up
		addGestureRecognizer(uges)

		let dges = UISwipeGestureRecognizer(target: self, action: #selector(doClose))
		dges.direction = .Down
		addGestureRecognizer(dges)

		let lges = UILongPressGestureRecognizer(target: self, action: #selector(tapLong(_:)))
		addGestureRecognizer(lges)

		layout()
	}

	func tapLong(ges: UILongPressGestureRecognizer) {
		if ges.state == .Began { Player.sharedInstance().speedup = true }
		else if ges.state != .Cancelled { Player.sharedInstance().speedup = false }
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		layout()
	}

	func layout() {

		openBtn.frame = bounds.resize(44, 66, .TopRight)

		if !opened {
			prevBtn.hidden = true
			volSlider.hidden = true
			svoliv.hidden = true
			mvoliv.hidden = true
			progressLabel.hidden = true
			durationLabel.hidden = true
			keyLayer.hidden = true
			speLayer.hidden = true
			borderLayer.hidden = false
			smpBtn.hidden = true
			loopBtn.hidden = true
			titleLabel.frame = bounds.resize(-44 * 3, 66, .Top).offset(-22, 0)
			progressSlider.frame = bounds.resize(0, 3, .Top).offset(0, 66 - 3)
			playBtn.frame = bounds.resize(44, 66, .TopLeft)
			nextBtn.frame = bounds.resize(44, 66, .TopRight).offset(-44, 0)
			borderLayer.frame = CGRect(0, 0, width, 0.5)

		} else {
			prevBtn.hidden = false
			volSlider.hidden = false
			svoliv.hidden = false
			mvoliv.hidden = false
			progressLabel.hidden = false
			durationLabel.hidden = false
			smpBtn.hidden = false
			loopBtn.hidden = false
			borderLayer.hidden = true

			var y: CGFloat = 0

			if width < height {
				keyLayer.hidden = false
				speLayer.hidden = false
				keyLayer.frame = CGRect(0, 66, width, width * (136 / 224))
				speLayer.frame = CGRect(0, 66 + keyLayer.frame.height, width, width * (64 / 256))
				spmaskLayer.frame = speLayer.bounds

				y = speLayer.frame.origin.y + speLayer.frame.size.height

			} else {
				keyLayer.hidden = true
				speLayer.hidden = true
				y = 66
			}

			progressSlider.frame = bounds.resize(0, 3, .Top).offset(0, y)
			progressLabel.frame = bounds.resize(100, 20, .TopLeft).offset(5, y + 5)
			durationLabel.frame = bounds.resize(100, 20, .TopRight).offset(-5, y + 5)

			y = height - 44 * 5

			titleLabel.frame = bounds.resize(-20, 44, .Top).offset(0, y + 12)
			descLabel.frame = bounds.resize(-20, 22, .Top).offset(0, y + 64)
			y += 44 * 3

			let div = (width - 44) / 4
			smpBtn.center = CGPoint(x: div * 0 + 22, y: y)
			prevBtn.center = CGPoint(x: div * 1 + 22, y: y)
			playBtn.center = CGPoint(x: div * 2 + 22, y: y)
			nextBtn.center = CGPoint(x: div * 3 + 22, y: y)
			loopBtn.center = CGPoint(x: div * 4 + 22, y: y)
			y += 44

			svoliv.frame = bounds.resize(18, 18, .TopLeft).offset(30, y + 13)
			mvoliv.frame = bounds.resize(18, 18, .TopRight).offset(-30, y + 13)
			volSlider.frame = bounds.resize(-110, 44, .Top).offset(0, y)

		}
		setNeedsDisplay()
	}

	func tapPlay() {
		playBtn.selected = !playBtn.selected
		Player.sharedInstance().pause(playBtn.selected)
	}

	func tapPrev() {
		Player.sharedInstance().goPrev()
	}

	func tapNext() {
		Player.sharedInstance().goNext()
	}

	func tapArrow(btn: UIButton) {
		if !opened {
			doOpen()
		} else {
			doClose()
		}
	}

	func doOpen() {
		if opened { return }
		opened = true
		openBtn.setImage(UIImage(named: "arrow_down"), forState: .Normal)
		UIView.animateWithDuration(0.3) {
			self.frame = self.superview!.bounds
			self.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
			self.layout()
		}
	}

	func doClose() {
		if !opened { return }
		opened = false
		openBtn.setImage(UIImage(named: "arrow_up"), forState: .Normal)
		UIView.animateWithDuration(0.3) {
			self.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
			self.frame = self.superview!.bounds.resize(0, 66, .Bottom)
			self.layout()
		}
	}

	func tapSmp() {
		var idx = 0
		let params: [Int] = [44100, 48000, 62500, 22050]
		if let ci = params.indexOf(Player.sharedInstance().samplingRate) { idx = (ci + 1) % params.count }

		Player.sharedInstance().samplingRate = params[idx]
		smpLabel.text = String(format: "%.1fk", Float(Player.sharedInstance().samplingRate) / 1000)
		titleLabel.text = ""
		descLabel.text = ""
		Player.redrawKey(keyLayer, speana: speLayer, paint: false)
	}

	func tapLoop() {
		var cnt = Player.sharedInstance().loopCount
		cnt = cnt + 1
		if cnt > 3 { cnt = 1 }

		Player.sharedInstance().loopCount = cnt
		loopLabel.text = "\( Player.sharedInstance().loopCount )"
	}

	func changeVolume() {
		Player.sharedInstance().volume = volSlider.value
	}

	convenience init() {
		self.init(frame: .zero)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}

	func didEnd() { }
	func didStart() {
		titleLabel.text = Player.sharedInstance().title
		descLabel.text = Player.sharedInstance().file?.lastPathComponent
	}
	func didChangeSecond() {
		let current = Player.sharedInstance().current
		let duration = Player.sharedInstance().duration
		let remain = duration - current

		progressLabel.text = String(format: "%0d:%02d", current / 60, current % 60)
		durationLabel.text = String(format: "-%0d:%02d", remain / 60, remain % 60)
		progressSlider.value = Float(current) / Float(duration)
	}

	func didChangeStatus() {
		if keyLayer.hidden { return }
		Player.redrawKey(keyLayer, speana: speLayer, paint: true)
	}

}

