
import WebKit

class InfoVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "information ver" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
        let wview = WKWebView(frame: view.bounds)
        view.addSubview(wview)
        wview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wview.load(URLRequest(url: URL(string: "https://nagisaworks.com/mdxplayer/info/")!))
    }
}
