# MDX Player for iOS

<p align="center">
  <a href="https://itunes.apple.com/us/app/mdx-player/id639136241?l=ja&ls=1&mt=8">
    <img src="https://img.shields.io/badge/App_Store-Download-blue.svg" alt="App Store">
  </a>
  <img src="https://img.shields.io/badge/platform-iOS%2015.0+-lightgrey.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.0+-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/license-BSD-green.svg" alt="License">
</p>

懐かしいX68000のMDXファイルを再生できるiOSプレイヤーアプリ

MDX is a sound file format designed to be played on the Sharp X68000.

- [Wikipedia: X68000](http://en.wikipedia.org/wiki/X68000)
- [Wikipedia: X68000's MDX](http://en.wikipedia.org/wiki/X68000%27s_MDX)

## Features

- **Background Playback** - 継続的な音楽再生をサポート
- **Remote Control** - iOS標準のメディアコントロールに対応
- **Repeat Playback** - シームレスなループ再生機能
- **Dropbox Integration** - クラウドストレージとの統合
- **Real-time Visualization** - X68000オリジナルのキーボード表示とスペクトラムアナライザー
- **File Management** - ローカルおよびクラウドファイルの一元管理

## Requirements

- iOS 15.0以降
- Xcode 15以降（ビルドする場合）

## How to Build

### 1. CocoaPodsのインストール

まず[CocoaPods](http://cocoapods.org/)をインストールします：

```bash
$ sudo gem install cocoapods
```

### 2. 依存関係のインストール

プロジェクトディレクトリで以下を実行：

```bash
$ pod install
```

### 3. Xcodeで開く

生成された`.xcworkspace`ファイルを開きます：

```bash
$ open mdxplayer.xcworkspace
```

**注意**: `.xcodeproj`ではなく`.xcworkspace`を開いてください。

## Dependencies

- [SwiftyDropbox](https://github.com/dropbox/SwiftyDropbox) - Dropbox SDK

## About MDX Format

MDXデコード部は[GORRYさんのGAMDX](http://gorry.haun.org/android/gamdx/)からのポートとなります。

MDX、ADPCM、OPMなどのライセンスを含むGAMDXについては、上記リンクを参照してください。

## License

- **本アプリケーション**: BSD License
- **GAMDX (MDXデコーダ)**: GAMDXのライセンスに準拠
- **SwiftyDropbox**: Dropboxのライセンスに準拠

詳細は各コンポーネントのライセンスファイルを参照してください。

## Links

- [App Store](https://itunes.apple.com/us/app/mdx-player/id639136241?l=ja&ls=1&mt=8)
- [GAMDX by GORRY](http://gorry.haun.org/android/gamdx/)

## Credits

- MDXデコーダ: [GORRY](http://gorry.haun.org/)
- Original X68000 MXDRV: milk., K.MAEKAWA, Missy.M, Yatsube

---

Made with care for X68000 music lovers

