
import UIKit


public extension CGSize {
	init(_ w: CGFloat, _ h: CGFloat) { self.init(width: w, height: h) }
	func calc(_ block: (inout CGSize) -> Void) -> CGSize { var v = self; block(&v); return v }

	var zeroPointRect: CGRect { return CGRect(origin: .zero, size: self) }
	func scale(_ scale: CGFloat) -> CGSize { return CGSize(width * scale, height * scale) }
	func aspectFit(_ tsz: CGSize) -> CGSize { return aspectCalc(tsz, isFit: true) }
	func aspectFill(_ tsz: CGSize) -> CGSize { return aspectCalc(tsz, isFit: false) }

	func aspectCalc(_ tsz: CGSize, isFit: Bool) -> CGSize {
		if width <= 0 || height <= 0 { return CGSize.zero }
		let xz: CGFloat = tsz.width / width
		let yz: CGFloat = tsz.height / height
		let z: CGFloat = ((xz < yz) == isFit) ? xz : yz
		return CGSize(ceil(width * z), ceil(height * z))
	}
}

public extension CGRect {
	init(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) { self.init(x: x, y: y, width: w, height: h) }
	init(size: CGSize) { self.init(origin: .zero, size: size) }
	init(width: CGFloat, height: CGFloat) { self.init(origin: .zero, size: CGSize(width, height)) }

	func calc(_ block: (inout CGRect) -> Void) -> CGRect { var v = self; block(&v); return v }

	func inset(_ dx: CGFloat, _ dy: CGFloat) -> CGRect {
		return self.insetBy(dx: dx, dy: dy)
	}

	func offset(_ dx: CGFloat, _ dy: CGFloat) -> CGRect {
		return self.offsetBy(dx: dx, dy: dy)
	}

	func scale(_ scale: CGFloat, alignment: Alignment) -> CGRect {
		let sz = size.scale(scale)
		return resize(sz.width, sz.height, alignment)
	}

	public enum Alignment: Int {
		case center, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
	}

	func resize(_ iw: CGFloat, _ ih: CGFloat, _ alignment: Alignment) -> CGRect {
		var x = origin.x
		var y = origin.y
		let w = iw > 0 ? iw : (size.width + iw)
		let h = ih > 0 ? ih : (size.height + ih)

		let cx = x + (width - w) / 2
		let cy = y + (height - h) / 2
		let rx = x + width - w
		let by = y + height - h

		switch alignment {
		case .center: x = cx;y = cy
		case .top: x = cx
		case .left: y = cy
		case .right: y = cy;x = rx
		case .topLeft: break
		case .topRight: x = rx
		case .bottom: x = cx; y = by
		case .bottomLeft: y = by
		case .bottomRight: x = rx;y = by
		}
		return CGRect(x, y, w, h)
	}
}


public extension UIViewController {
	var width: CGFloat { return view.bounds.size.width }
	var height: CGFloat { return view.bounds.size.height }
	var bounds: CGRect { return view.bounds }
	var frame: CGRect { return view.frame }

	func showInfo(_ msg: String, okTitle: String = "OK", title: String = "") {
		let av = UIAlertController(title: title, message: msg, preferredStyle: .alert)
		av.addAction(UIAlertAction(title: NSLocalizedString(okTitle, comment: ""), style: .default, handler: nil))
		present(av, animated: true, completion: nil)
	}

	func showOKCancel(_ msg: String, okTitle: String = "OK", cancelTitle: String = "Cancel", title: String = "", cancel: (() -> Void)? = nil, completion: @escaping (() -> Void)) {
		let av = UIAlertController(title: "", message: msg, preferredStyle: .alert)
		av.addAction(UIAlertAction(title: NSLocalizedString(okTitle, comment: ""), style: .default, handler: { action in completion() }))
		av.addAction(UIAlertAction(title: NSLocalizedString(cancelTitle, comment: ""), style: .cancel, handler: { action in cancel?() }))
		present(av, animated: true, completion: nil)
	}

	func showAsk(_ msg: String, list: [String], cancelTitle: String = "Cancel", title: String = "", completion: @escaping ((_ index: Int) -> Void)) {
		let av = UIAlertController(title: title, message: msg, preferredStyle: .alert)

		for i in 0 ..< list.count {
			let v: Int = i // copy val
			av.addAction(UIAlertAction(title: list[i], style: .default, handler: { action in completion(v) }))
		}
		av.addAction(UIAlertAction(title: NSLocalizedString(cancelTitle, comment: ""), style: .cancel, handler: nil))
		present(av, animated: true, completion: nil)
	}

}

public extension UIView {
	var width: CGFloat { return bounds.size.width }
	var height: CGFloat { return bounds.size.height }
	var size: CGSize { return bounds.size }
}

public extension UIButton {
	static func imageButton(_ image: UIImage?, frame: CGRect, target: AnyObject? = nil, action: Selector? = nil) -> UIButton {
		let btn = UIButton(type: .custom)
		btn.frame = frame
		btn.setImage(image, for: UIControlState())
		if let t = target { btn.addTarget(t, action: action!, for: UIControlEvents.touchUpInside) }
		return btn
	}
}
