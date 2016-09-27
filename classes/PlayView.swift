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
		iv.contentMode = .scaleAspectFill
		iv.clipsToBounds = true
		iv.frame = bounds
		iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
		smpLabel.textAlignment = .center
		smpLabel.font = .systemFont(ofSize: 9)
		smpLabel.text = "44.1k"
		smpLabel.textColor = UIColor.black

		loopBtn.addSubview(loopLabel)
		loopLabel.frame = loopBtn.bounds
		loopLabel.textAlignment = .center
		loopLabel.font = .systemFont(ofSize: 10)
		loopLabel.text = "1"
		loopLabel.textColor = UIColor.mdxColor

		titleLabel.textAlignment = .center
		titleLabel.font = UIFont(name: "KH-Dot-Kodenmachou-16-Ki", size: 16)
		titleLabel.textColor = .white
		titleLabel.numberOfLines = 3

		descLabel.textAlignment = .center
		descLabel.font = .systemFont(ofSize: 12)
		descLabel.textColor = .lightGray

		progressLabel.textColor = .lightGray
		progressLabel.font = .systemFont(ofSize: 12)
		progressLabel.textAlignment = .left

		durationLabel.textColor = .lightGray
		durationLabel.font = .systemFont(ofSize: 12)
		durationLabel.textAlignment = .right

		progressSlider.setThumbImage(UIImage(), for: .normal)
		progressSlider.maximumTrackTintColor = UIColor(white: 0, alpha: 0.2)

		volSlider.setThumbImage(UIImage(named: "volume_thumb"), for: .normal)

		openBtn.addTarget(self, action: #selector(tapArrow(_:)), for: .touchUpInside)

		playBtn.setImage(UIImage(named: "play"), for: .selected)
		playBtn.addTarget(self, action: #selector(tapPlay), for: .touchUpInside)

		prevBtn.addTarget(self, action: #selector(tapPrev), for: .touchUpInside)
		nextBtn.addTarget(self, action: #selector(tapNext), for: .touchUpInside)

		smpBtn.addTarget(self, action: #selector(tapSmp), for: .touchUpInside)
		loopBtn.addTarget(self, action: #selector(tapLoop), for: .touchUpInside)

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
		volSlider.addTarget(self, action: #selector(changeVolume), for: .valueChanged)

		loopLabel.text = "\( Player.sharedInstance().loopCount )"
		smpLabel.text = String(format: "%.1fk", Float(Player.sharedInstance().samplingRate) / 1000)

		borderLayer.backgroundColor = UIColor(white: 200 / 255, alpha: 1).cgColor
		borderLayer.frame = CGRect(0, 0, width, 1)
		layer.addSublayer(borderLayer)

		let uges = UISwipeGestureRecognizer(target: self, action: #selector(doOpen))
		uges.direction = .up
		addGestureRecognizer(uges)

		let dges = UISwipeGestureRecognizer(target: self, action: #selector(doClose))
		dges.direction = .down
		addGestureRecognizer(dges)

		let lges = UILongPressGestureRecognizer(target: self, action: #selector(tapLong(_:)))
		addGestureRecognizer(lges)

		layout()
	}

	func tapLong(_ ges: UILongPressGestureRecognizer) {
		if ges.state == .began { Player.sharedInstance().speedup = true }
		else if ges.state != .cancelled { Player.sharedInstance().speedup = false }
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		layout()
	}

	func layout() {

		openBtn.frame = bounds.resize(44, 66, .topRight)

		if !opened {
			prevBtn.isHidden = true
			volSlider.isHidden = true
			svoliv.isHidden = true
			mvoliv.isHidden = true
			progressLabel.isHidden = true
			durationLabel.isHidden = true
			keyLayer.isHidden = true
			speLayer.isHidden = true
			borderLayer.isHidden = false
			smpBtn.isHidden = true
			loopBtn.isHidden = true
			titleLabel.frame = bounds.resize(-44 * 3, 66, .top).offset(-22, 0)
			progressSlider.frame = bounds.resize(0, 3, .top).offset(0, 66 - 3)
			playBtn.frame = bounds.resize(44, 66, .topLeft)
			nextBtn.frame = bounds.resize(44, 66, .topRight).offset(-44, 0)
			borderLayer.frame = CGRect(0, 0, width, 0.5)

		} else {
			prevBtn.isHidden = false
			volSlider.isHidden = false
			svoliv.isHidden = false
			mvoliv.isHidden = false
			progressLabel.isHidden = false
			durationLabel.isHidden = false
			smpBtn.isHidden = false
			loopBtn.isHidden = false
			borderLayer.isHidden = true

			var y: CGFloat = 0

			if width < height {
				keyLayer.isHidden = false
				speLayer.isHidden = false
				keyLayer.frame = CGRect(0, 66, width, width * (136 / 224))
				speLayer.frame = CGRect(0, 66 + keyLayer.frame.height, width, width * (64 / 256))
				spmaskLayer.frame = speLayer.bounds

				y = speLayer.frame.origin.y + speLayer.frame.size.height

			} else {
				keyLayer.isHidden = true
				speLayer.isHidden = true
				y = 66
			}

			progressSlider.frame = bounds.resize(0, 3, .top).offset(0, y)
			progressLabel.frame = bounds.resize(100, 20, .topLeft).offset(5, y + 5)
			durationLabel.frame = bounds.resize(100, 20, .topRight).offset(-5, y + 5)

			y = height - 44 * 5

			titleLabel.frame = bounds.resize(-20, 44, .top).offset(0, y + 12)
			descLabel.frame = bounds.resize(-20, 22, .top).offset(0, y + 64)
			y += 44 * 3

			let div = (width - 44) / 4
			smpBtn.center = CGPoint(x: div * 0 + 22, y: y)
			prevBtn.center = CGPoint(x: div * 1 + 22, y: y)
			playBtn.center = CGPoint(x: div * 2 + 22, y: y)
			nextBtn.center = CGPoint(x: div * 3 + 22, y: y)
			loopBtn.center = CGPoint(x: div * 4 + 22, y: y)
			y += 44

			svoliv.frame = bounds.resize(18, 18, .topLeft).offset(30, y + 13)
			mvoliv.frame = bounds.resize(18, 18, .topRight).offset(-30, y + 13)
			volSlider.frame = bounds.resize(-110, 44, .top).offset(0, y)

		}
		setNeedsDisplay()
	}

	func tapPlay() {
		Player.sharedInstance().togglePause()
	}
    
    func didChangePause(to pause: Bool) {
        playBtn.isSelected = pause
    }

	func tapPrev() {
		Player.sharedInstance().goPrev()
	}

	func tapNext() {
		Player.sharedInstance().goNext()
	}

	func tapArrow(_ btn: UIButton) {
		if !opened {
			doOpen()
		} else {
			doClose()
		}
	}

	func doOpen() {
		if opened { return }
		opened = true
		openBtn.setImage(UIImage(named: "arrow_down"), for: .normal)
		UIView.animate(withDuration: 0.3, animations: {
			self.frame = self.superview!.bounds
			self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			self.layout()
		}) 
	}

	func doClose() {
		if !opened { return }
		opened = false
		openBtn.setImage(UIImage(named: "arrow_up"), for: .normal)
		UIView.animate(withDuration: 0.3, animations: {
			self.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
			self.frame = self.superview!.bounds.resize(0, 66, .bottom)
			self.layout()
		}) 
	}

	func tapSmp() {
		var idx = 0
		let params: [Int] = [44100, 48000, 62500, 22050]
		if let ci = params.index(of: Player.sharedInstance().samplingRate) { idx = (ci + 1) % params.count }

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
		if keyLayer.isHidden { return }
		Player.redrawKey(keyLayer, speana: speLayer, paint: true)
	}

}

