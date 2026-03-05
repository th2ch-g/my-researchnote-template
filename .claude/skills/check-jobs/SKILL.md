---
name: check-jobs
description: カレントディレクトリのSlurmジョブを監視し、異常終了時は最大3回まで自動再投入する。「ジョブを監視したい」「ジョブが終わったら教えて」「異常終了したら再投入して」「slurmジョブを見ておいて」などと言われたらこのスキルを使う。
---

# /check-jobs

カレントディレクトリのSlurmジョブを監視し、異常終了時は最大3回まで自動再投入するスキル。
Claudeの呼び出し回数を最小限に抑えるため、監視ループはBashスクリプトとして実行する。

## Phase 1: ジョブスクリプトの特定（Claude が実行）

1. カレントディレクトリの `*.sh` ファイルを探す
2. 各 `.sh` を読み、`#SBATCH` ディレクティブがあるものをSlurmジョブスクリプトと判断する
3. `squeue -u $USER --noheader -o "%i %j %T"` を実行して現在のジョブ一覧を取得する
4. `#SBATCH --job-name` または `#SBATCH -J` の値と照合して監視対象のジョブIDを特定する
   - ジョブIDが特定できない場合はユーザーに確認する
5. 各ジョブについて以下を整理する:
   - ジョブID
   - 対応する `.sh` ファイルパス（再投入用）
   - `*.out` / `*.err` ファイルのパターン（`#SBATCH --output` / `--error` から取得。なければ `slurm-<jobid>.out`）

## Phase 2: 監視スクリプトの生成・実行（Bash が担当、Claude は介在しない）

Phase 1 で特定した情報を埋め込んで、以下の `_check_jobs.sh` をカレントディレクトリに生成し、`bash _check_jobs.sh` で実行する。

`_check_jobs.sh` のテンプレート（`JOB_IDS` と `JOB_SCRIPTS` は Phase 1 の結果で置き換える）:

```bash
#!/bin/bash
# 自動生成された監視スクリプト（/check-jobs スキルにより生成）

JOB_IDS=(<Phase1で特定したジョブIDをスペース区切りで列挙>)
JOB_SCRIPTS=(<対応する.shファイルパスをスペース区切りで列挙、JOB_IDSと同じ順序>)
MAX_RETRY=3
SLEEP_SEC=60

declare -A retry_count
declare -A done_jobs  # 完了済みジョブを記録して再チェックを防ぐ

for jid in "${JOB_IDS[@]}"; do
    retry_count[$jid]=0
done

echo "[check-jobs] 監視開始: ${JOB_IDS[*]}"

while true; do
    all_done=true

    for i in "${!JOB_IDS[@]}"; do
        jid="${JOB_IDS[$i]}"
        script="${JOB_SCRIPTS[$i]}"

        # 完了済みジョブはスキップ
        if [[ -n "${done_jobs[$jid]}" ]]; then
            continue
        fi

        state=$(squeue --job "$jid" --noheader -o "%T" 2>/dev/null)

        if [[ -z "$state" ]]; then
            # squeue に表示されない = 終了済み → sacct で最終状態を確認
            final=$(sacct -j "$jid" --noheader -o "State" 2>/dev/null | head -1 | tr -d ' ')

            if [[ "$final" == "COMPLETED" ]]; then
                echo "[check-jobs] ジョブ $jid: 正常終了"
                done_jobs[$jid]=1

            elif [[ "$final" == "FAILED" || "$final" == "CANCELLED" || "$final" == "TIMEOUT" || "$final" == "NODE_FAIL" ]]; then
                echo "[check-jobs] ジョブ $jid: 異常終了 (状態: $final)"

                if [[ ${retry_count[$jid]} -lt $MAX_RETRY ]]; then
                    retry_count[$jid]=$(( ${retry_count[$jid]} + 1 ))
                    echo "[check-jobs] ジョブ $jid: 再投入 (${retry_count[$jid]}/${MAX_RETRY}回目)"
                    new_jid=$(sbatch "$script" 2>&1 | awk '{print $NF}')

                    # sbatch の出力が数値IDかバリデーション
                    if [[ "$new_jid" =~ ^[0-9]+$ ]]; then
                        echo "[check-jobs] 新ジョブID: $new_jid (スクリプト: $script)"
                        JOB_IDS[$i]="$new_jid"
                        retry_count[$new_jid]=${retry_count[$jid]}
                        unset retry_count[$jid]
                        all_done=false
                    else
                        echo "[check-jobs] エラー: sbatch が失敗しました: $new_jid"
                        echo "SBATCH_ERROR: $jid $script" >> _check_jobs_failed.log
                        done_jobs[$jid]=1
                    fi

                else
                    echo "[check-jobs] ジョブ $jid: 最大再投入回数(${MAX_RETRY}回)に達しました。手動確認が必要です。"
                    echo "RETRY_LIMIT_REACHED: $jid $script" >> _check_jobs_failed.log
                    done_jobs[$jid]=1
                fi

            else
                echo "[check-jobs] ジョブ $jid: 状態不明 ($final)。スキップします。"
                done_jobs[$jid]=1
            fi

        elif [[ "$state" == "RUNNING" || "$state" == "PENDING" || "$state" == "COMPLETING" ]]; then
            all_done=false
        fi
    done

    if $all_done; then
        echo "[check-jobs] 全ジョブ終了。ログ確認フェーズに移行します。"
        break
    fi

    sleep $SLEEP_SEC
done
```

## Phase 3: ログの解釈（Claude が実行）

スクリプト終了後:

1. `*.out` と `*.err` をすべて読み込む
2. 以下の観点で正常/異常を判断する:
   - エラーメッセージ・例外・コアダンプの有無
   - 計算が最後まで実行されたか（終了行・収束の確認）
   - `_check_jobs_failed.log` が存在する場合は内容を報告
3. 結果を以下の形式でまとめて報告する:

```
## /check-jobs 結果サマリー

### 正常終了したジョブ
- ジョブ名 (ID: xxx)

### 異常終了・要確認のジョブ
- ジョブ名 (ID: xxx): 理由...

### ログから確認された注意点
- ...
```

4. `TODO.md` に該当タスクがある場合、ステータス更新を提案する。

## 注意

- `_check_jobs.sh` は実行後も削除せず残す（再実行・デバッグ用）
- デフォルトの `SLEEP_SEC=60` は短時間ジョブ向け。数時間規模のMD計算なら生成前にユーザーに確認して `300` 程度に変更する
