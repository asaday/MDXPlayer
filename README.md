# MDX Player for iOS

懐かしいX68000のMDXファイルのプレイヤー

MDX is sound file format designed to be played on the Sharp X68000
see here
http://en.wikipedia.org/wiki/X68000
http://en.wikipedia.org/wiki/X68000%27s_MDX

* バッググラウンドプレイ
* リモートコントロール
* ループプレイ
* Dropbox (要key)

mdxデコード部はGORRYさんのGAMDXからのポートとなります。
mdx,ADPCM,OPMなどのLicense等含めGAMDXにつきましてはこちらを参照願います。
http://gorry.haun.org/android/gamdx/

DropboxSDK部はDropboxのLicenseを参照して下さい。

その他のコードはBSD Licenseとします。

AppStore  
[https://itunes.apple.com/us/app/mdx-player/id639136241?l=ja&ls=1&mt=8
](https://itunes.apple.com/us/app/mdx-player/id639136241?l=ja&ls=1&mt=8)

---

### how to make

1. install [cocoapods](http://cocoapods.org/)

install and cocoapods, and

	$ pod install

2. add keys.h

keys.h is for Dropbox client key  
xcode say keys.h not found.  
make keys.h

	#define DROPBOX_KEY	@"dropbox client key"
 	#define DROPBOX_SECRET @"dropbox client secret key"

please see [https://www.dropbox.com/developers/](https://www.dropbox.com/developers/)


### attention

This code is for 32bit only.
