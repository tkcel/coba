# /export-pdf

Markdownファイルを PDF にエクスポートする。

## いつ使うか

- 議事録や資料を PDF で共有したいとき
- `$ARGUMENTS` でファイルパスを指定する

## 手順

1. `$ARGUMENTS` で指定されたファイルを確認する
   - 指定がなければ「ファイルを指定してください」と案内して終了
   - ファイルが存在しなければエラーを表示して終了

2. 以下のコマンドで PDF を生成する:

```bash
npx md-to-pdf <入力ファイル> --pdf-options '{"format":"A4","margin":{"top":"20mm","right":"20mm","bottom":"20mm","left":"20mm"}}' --css 'body { font-family: "Hiragino Kaku Gothic ProN", "Noto Sans JP", sans-serif; font-size: 12px; line-height: 1.8; } table { border-collapse: collapse; width: 100%; margin: 1em 0; } th, td { border: 1px solid #ccc; padding: 8px; text-align: left; } th { background: #f5f5f5; } h1 { border-bottom: 2px solid #333; padding-bottom: 4px; } h2 { border-bottom: 1px solid #ccc; padding-bottom: 4px; } h3 { color: #555; }'
```

3. 生成された PDF のパスをユーザーに報告する
   - 出力先は入力ファイルと同じディレクトリに `.pdf` 拡張子で出力される（md-to-pdf のデフォルト動作）

## 注意

- ファイルの削除は行わない（元の .md はそのまま残す）
