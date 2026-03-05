# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

MD計算・構造予測などの計算化学研究のための作業ノートテンプレート。日付ベースのディレクトリ管理とGitHub Issueを組み合わせた研究記録管理システム。

## コマンド

```bash
make            # init + create を実行（新しい作業日のディレクトリを作成）
make init       # .env に BASEDIR=<現在のPWD> を書き込む
make create     # YYYYMMDD/ ディレクトリと README.md を作成
make push       # git add -A && commit "add" && push
make release    # vYYYY.M.D タグを作成してプッシュ（GitHub Releaseがトリガーされる）
```

## ディレクトリ構造

```
YYYYMMDD/          # 作業日ごとのディレクトリ（make create で自動生成）
  README.md        # その日の作業メモ
database/          # 構造ファイル等のデータベース（Git管理対象）
misc/              # 雑多なファイル（.gitignore で管理外）
.env               # BASEDIR 変数（make init で生成、Git管理外）
```

## 環境変数

- `BASEDIR`: このレポジトリのルート絶対パス。スクリプトから参照する場合は `.env` を読み込む

## 計算化学ツールの対応

以下のツールの入出力ファイルはGit管理外（`.gitignore`に列挙）:

| ツール | 主な拡張子 |
|--------|-----------|
| GROMACS | `.mdp`, `.gro`, `.top`, `.tpr`, `.xtc`, `.edr`, `.cpt` |
| AMBER | `.prmtop`, `.inpcrd`, `.parm7`, `.rst7`, `.mdin` |
| Gaussian | `.gjf`, `.com`, `.chk` |
| 共通構造ファイル | `.pdb`, `.cif` |

計算結果（`.npy`, `*out`, `*err`）も管理外。**計算に使ったスクリプト・パラメータ・解析コードはREADME.mdやdatabase/に記録すること。**

## GitHub Issue テンプレート

研究ノートはGitHub Issueで管理する:

- **TODO**: タスク管理
- **MEMO**: URLやメモの記録
- **RelatedWorks**: 論文メモ（DOI / Abstract / Method / Result / Discussion / References）

## 研究の自律実行ガイドライン

新しい計算タスクを開始する際:
1. `make create` で当日ディレクトリを作成
2. YYYYMMDD/README.md に計算の目的・パラメータ・結果を記録
3. 構造ファイルや再利用するデータは `database/` に格納
4. 計算が完了したら `make push` でスクリプト・メモをコミット

リリースは日付タグ (`vYYYY.M.D`) で管理され、GitHub Actions が自動でリリースを作成する。
