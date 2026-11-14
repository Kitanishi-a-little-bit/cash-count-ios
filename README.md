# お金カウント

レジ・金庫のお金を数える iOS 17 以降向け SwiftUI アプリです。
紙幣は枚数、硬貨はバラ枚数とロール数（1本50枚）を入力します。
入力は端末内に自動保存されます。ログイン・外部サービスは不要です。
各欄は最大6桁。リセットは選択中のレジまたは金庫だけに適用されます。

## Mac での開発

Xcode と Homebrew が必要です。

```sh
brew install xcodegen
cd /path/to/cash-count-ios
xcodegen generate
open CashCount.xcodeproj
```

CashCount スキームと iPhone シミュレータを選び、Run で起動、Test でテストします。
生成された Xcode プロジェクトは管理対象外です。構成は project.yml で管理します。
実機・配布用の署名設定は別途必要です。

## GitHub Actions

main への push、プルリクエスト、Actions 画面の手動実行で、macOS 上で
シミュレータ用のビルドと XCTest を実行します。署名用の秘密情報は不要です。
テスト結果は Actions の ios-test-results アーティファクトで確認できます。

Linux では Xcode / iOS SDK が使えないため、iOS ビルド・テストは実行できません。
画面の見た目、キーボード操作、小画面・大きな文字での表示は Mac のシミュレータまたは実機で確認してください。
