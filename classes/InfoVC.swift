

class InfoVC: UIViewController, UIWebViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "information ver" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
        let wview = UIWebView(frame: view.bounds)
        view.addSubview(wview)
        wview.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        wview.delegate = self
        wview.loadRequest(URLRequest(url: URL(string: "https://ipn.sakura.ne.jp/mdxplayer/info/")!))
    }
}
