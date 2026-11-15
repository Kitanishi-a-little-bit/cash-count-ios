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

## TestFlight 配布

Bundle ID は `com.rejitokinko.cashcount`、端末の表示名は「レジと金庫」です。
App Store Connect のアプリ名は「レジと金庫：紙幣・硬貨・棒金をまとめて計算」です。

GitHub リポジトリの Actions Secrets に次を登録します。

- `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_PRIVATE_KEY`：App Store Connect チーム API キー
- `IOS_DISTRIBUTION_P12_BASE64`：秘密鍵を含む Apple Distribution 証明書の p12 を Base64 化したもの
- `IOS_DISTRIBUTION_P12_PASSWORD`：p12 の保護パスワード
- `IOS_PROVISION_PROFILE_BASE64`：この Bundle ID と上記証明書に対応する App Store 配布プロファイルの Base64

Actions → Upload to TestFlight → Run workflow → main で手動実行します。
通常の push では配布しません。ビルド番号は配布ワークフローの実行番号と再実行番号です。
macOS ランナーの Xcode 26 以降で署名・アーカイブし、App Store Connect にアップロードします。
証明書とプロファイルは一時キーチェーン等に入れ、終了時に削除します。
秘密情報をリポジトリにコミットしないでください。

成功後も Apple 側の処理に時間がかかります。App Store Connect の TestFlight で処理完了を確認し、
内部テストグループにビルドと自分を追加して iPhone の TestFlight からインストールします。
このワークフローは App Store 本番公開や審査提出を行いません。
