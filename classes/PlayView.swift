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

        keyLayer.magnificationFilter = CALayerContentsFilter.nearest
        speLayer.magnificationFilter = CALayerContentsFilter.nearest
        spmaskLayer.magnificationFilter = CALayerContentsFilter.nearest

        Player.prepareMask(spmaskLayer)

        layer.addSublayer(keyLayer)
        layer.addSublayer(speLayer)
        speLayer.addSublayer(spmaskLayer)
        Player.redrawKey(keyLayer, speana: speLayer, paint: false)

        Player.sharedInstance().volume = 1
        volSlider.value = Player.sharedInstance().volume
        volSlider.addTarget(self, action: #selector(changeVolume), for: .valueChanged)

        loopLabel.text = "\(Player.sharedInstance().loopCount)"
        if Player.sharedInstance().loopCount == 0 { loopLabel.text = "∞" }

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

    @objc func tapLong(_ ges: UILongPressGestureRecognizer) {
        if ges.state == .began { Player.sharedInstance().speedup = true }
        else if ges.state != .cancelled { Player.sharedInstance().speedup = false }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }

    func layout() {
        if !opened {
            let sb = bounds
            openBtn.frame = sb.resize(44, 66, .topRight)

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
            titleLabel.frame = sb.resize(-44 * 3, 66, .top).offset(-22, 0)
            progressSlider.frame = sb.resize(0, 3, .top).offset(0, 66 - 3)
            playBtn.frame = sb.resize(44, 66, .topLeft)
            nextBtn.frame = sb.resize(44, 66, .topRight).offset(-44, 0)
            borderLayer.frame = CGRect(0, 0, width, 0.5)

            setNeedsDisplay()
            return
        }

        let sb = bounds.inset(by: safeAreaInsets)
        openBtn.frame = sb.resize(44, 66, .topRight)

        prevBtn.isHidden = false
        volSlider.isHidden = false
        svoliv.isHidden = false
        mvoliv.isHidden = false
        progressLabel.isHidden = false
        durationLabel.isHidden = false
        smpBtn.isHidden = false
        loopBtn.isHidden = false
        borderLayer.isHidden = true

        var y: CGFloat = 66

        if width < height {
            keyLayer.isHidden = false
            speLayer.isHidden = false
            let kh = ceil(width * (136 / 224))
            keyLayer.frame = sb.resize(width, kh, .top).offset(0, y)
            let sh = width * (64 / 256)
            speLayer.frame = sb.resize(width, sh, .top).offset(0, y + kh)
            spmaskLayer.frame = speLayer.bounds
            y += kh + sh
        } else {
            keyLayer.isHidden = true
            speLayer.isHidden = true
        }
        progressSlider.frame = sb.resize(0, 3, .top).offset(0, y)
        progressLabel.frame = sb.resize(100, 20, .topLeft).offset(5, y + 5)
        durationLabel.frame = sb.resize(100, 20, .topRight).offset(-5, y + 5)
        y += 20

        let crc = sb.resize(0, sb.height - y, .bottom).resize(0, 44 * 4, .center) // control rect height=fix ypos=center in rest
        titleLabel.frame = crc.resize(-20, 44, .top).offset(0, 12)
        descLabel.frame = crc.resize(-20, 22, .top).offset(0, 64)

        let div = (crc.width - 44 * 2) / 4
        let brc = crc.resize(44, 44, .topLeft).offset(22, 44 * 2)
        smpBtn.frame = brc.offset(div * 0, 0)
        prevBtn.frame = brc.offset(div * 1, 0)
        playBtn.frame = brc.offset(div * 2, 0)
        nextBtn.frame = brc.offset(div * 3, 0)
        loopBtn.frame = brc.offset(div * 4, 0)

        volSlider.frame = crc.resize(-110, 44, .bottom)
        svoliv.frame = crc.resize(18, 18, .bottomLeft).offset(30, -13)
        mvoliv.frame = crc.resize(18, 18, .bottomRight).offset(-30, -13)

        setNeedsDisplay()
    }

    @objc func tapPlay() {
        Player.sharedInstance().togglePause()
    }

    func didChangePause(to pause: Bool) {
        playBtn.isSelected = pause
    }

    @objc func tapPrev() {
        Player.sharedInstance().goPrev()
    }

    @objc func tapNext() {
        Player.sharedInstance().goNext()
    }

    @objc func tapArrow(_: UIButton) {
        if !opened {
            doOpen()
        } else {
            doClose()
        }
    }

    @objc func doOpen() {
        if opened { return }
        opened = true
        openBtn.setImage(UIImage(named: "arrow_down"), for: .normal)
        UIView.animate(withDuration: 0.3, animations: {
            self.frame = self.superview!.bounds
            self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.layout()
        })
    }

    @objc func doClose() {
        if !opened { return }
        opened = false
        openBtn.setImage(UIImage(named: "arrow_up"), for: .normal)
        UIView.animate(withDuration: 0.3, animations: {
            self.setClose()
        })
    }

    func setClose() {
        opened = false
        autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        guard let sv = superview else { return }
        frame = sv.bounds.resize(0, 66 + sv.safeAreaInsets.bottom, .bottom)
        layout()
    }

    @objc func tapSmp() {
        var idx = 0
        let params: [Int] = [44100, 48000, 62500, 22050]
        if let ci = params.firstIndex(of: Player.sharedInstance().samplingRate) { idx = (ci + 1) % params.count }

        Player.sharedInstance().samplingRate = params[idx]
        smpLabel.text = String(format: "%.1fk", Float(Player.sharedInstance().samplingRate) / 1000)
        titleLabel.text = ""
        descLabel.text = ""
        Player.redrawKey(keyLayer, speana: speLayer, paint: false)
    }

    @objc func tapLoop() {
        var cnt = Player.sharedInstance().loopCount
        cnt = cnt + 1
        if cnt > 5 { cnt = 0 }

        Player.sharedInstance().loopCount = cnt
        if cnt == 0 {
            loopLabel.text = "∞"
        } else {
            loopLabel.text = "\(Player.sharedInstance().loopCount)"
        }
    }

    @objc func changeVolume() {
        Player.sharedInstance().volume = volSlider.value
    }

    convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func didEnd() {}
    func didStart() {
        titleLabel.text = Player.sharedInstance().title
        descLabel.text = Player.sharedInstance().file?.lastPathComponent
    }

    func didChangeSecond() {
        let current = Player.sharedInstance().current
        let duration = Player.sharedInstance().duration
        let remain = duration - current

        progressLabel.text = String(format: "%0d:%02d", current / 60, current % 60)
        if duration == 0 {
            durationLabel.text = "infinity"
            progressSlider.value = 1
        } else {
            durationLabel.text = String(format: "-%0d:%02d", remain / 60, remain % 60)
            progressSlider.value = Float(current) / Float(duration)
        }
    }

    func didChangeStatus() {
        if keyLayer.isHidden { return }
        Player.redrawKey(keyLayer, speana: speLayer, paint: true)
    }
}
