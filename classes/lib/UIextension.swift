
import UIKit


public extension CGSize {
	init(_ w: CGFloat, _ h: CGFloat) { self.init(width: w, height: h) }
	func calc(block: (inout CGSize) -> Void) -> CGSize { var v = self; block(&v); return v }

	var zeroPointRect: CGRect { return CGRect(origin: .zero, size: self) }
	func scale(scale: CGFloat) -> CGSize { return CGSize(width * scale, height * scale) }
	func aspectFit(tsz: CGSize) -> CGSize { return aspectCalc(tsz, isFit: true) }
	func aspectFill(tsz: CGSize) -> CGSize { return aspectCalc(tsz, isFit: false) }

	func aspectCalc(tsz: CGSize, isFit: Bool) -> CGSize {
		if width <= 0 || height <= 0 { return CGSizeZero }
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

	func calc(block: (inout CGRect) -> Void) -> CGRect { var v = self; block(&v); return v }

	func inset(dx: CGFloat, _ dy: CGFloat) -> CGRect {
		return CGRectInset(self, dx, dy)
	}

	func offset(dx: CGFloat, _ dy: CGFloat) -> CGRect {
		return CGRectOffset(self, dx, dy)
	}

	func scale(scale: CGFloat, alignment: Alignment) -> CGRect {
		let sz = size.scale(scale)
		return resize(sz.width, sz.height, alignment)
	}

	public enum Alignment: Int {
		case Center, Top, Bottom, Left, Right, TopLeft, TopRight, BottomLeft, BottomRight
	}

	func resize(iw: CGFloat, _ ih: CGFloat, _ alignment: Alignment) -> CGRect {
		var x = origin.x
		var y = origin.y
		let w = iw > 0 ? iw : (size.width + iw)
		let h = ih > 0 ? ih : (size.height + ih)

		let cx = x + (width - w) / 2
		let cy = y + (height - h) / 2
		let rx = x + width - w
		let by = y + height - h

		switch alignment {
		case .Center: x = cx;y = cy
		case .Top: x = cx
		case .Left: y = cy
		case .Right: y = cy;x = rx
		case .TopLeft: break
		case .TopRight: x = rx
		case .Bottom: x = cx; y = by
		case .BottomLeft: y = by
		case .BottomRight: x = rx;y = by
		}
		return CGRect(x, y, w, h)
	}
}


public extension UIViewController {
	var width: CGFloat { return view.bounds.size.width }
	var height: CGFloat { return view.bounds.size.height }
	var bounds: CGRect { return view.bounds }
	var frame: CGRect { return view.frame }

	func showInfo(msg: String, okTitle: String = "OK", title: String = "") {
		let av = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
		av.addAction(UIAlertAction(title: NSLocalizedString(okTitle, comment: ""), style: .Default, handler: nil))
		presentViewController(av, animated: true, completion: nil)
	}

	func showOKCancel(msg: String, okTitle: String = "OK", cancelTitle: String = "Cancel", title: String = "", cancel: (() -> Void)? = nil, completion: (() -> Void)) {
		let av = UIAlertController(title: "", message: msg, preferredStyle: .Alert)
		av.addAction(UIAlertAction(title: NSLocalizedString(okTitle, comment: ""), style: .Default, handler: { action in completion() }))
		av.addAction(UIAlertAction(title: NSLocalizedString(cancelTitle, comment: ""), style: .Cancel, handler: { action in cancel?() }))
		presentViewController(av, animated: true, completion: nil)
	}

	func showAsk(msg: String, list: [String], cancelTitle: String = "Cancel", title: String = "", completion: ((index: Int) -> Void)) {
		let av = UIAlertController(title: title, message: msg, preferredStyle: .Alert)

		for i in 0 ..< list.count {
			let v: Int = i // copy val
			av.addAction(UIAlertAction(title: list[i], style: .Default, handler: { action in completion(index: v) }))
		}
		av.addAction(UIAlertAction(title: NSLocalizedString(cancelTitle, comment: ""), style: .Cancel, handler: nil))
		presentViewController(av, animated: true, completion: nil)
	}

}

public extension UIView {
	var width: CGFloat { return bounds.size.width }
	var height: CGFloat { return bounds.size.height }
	var size: CGSize { return bounds.size }
}

public extension UIButton {
	static func imageButton(image: UIImage?, frame: CGRect, target: AnyObject? = nil, action: Selector = nil) -> UIButton {
		let btn = UIButton(type: .Custom)
		btn.frame = frame
		btn.setImage(image, forState: UIControlState.Normal)
		if let t = target { btn.addTarget(t, action: action, forControlEvents: UIControlEvents.TouchUpInside) }
		return btn
	}
}
