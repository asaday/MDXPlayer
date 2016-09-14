

class InfoVC: UIViewController, UIWebViewDelegate {

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "information"
		let wview = UIWebView(frame: view.bounds)
		self.view.addSubview(wview)
		wview.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]

		wview.delegate = self
		wview.loadRequest(NSURLRequest(URL: NSURL(string: "https://ipn.sakura.ne.jp/mdxplayer/info/")!))
	}

}

