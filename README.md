# kibana-tf

[elastic/elasticstack](https://registry.terraform.io/providers/elastic/elasticstack/latest/docs)
プロバイダーを使って、Kibanaのaction connector・alerting rule・workflowをコードで管理するTerraform構成です。
現在は`default`スペースのみを対象としています。

Terraformコマンドは基本的に[コンテナイメージ](terraform/Dockerfile)をOpenShift上で
動かして実行する前提です(`oc`コマンドでOpenShiftクラスタにログイン済みであること)。

## 構成

- `terraform/kibana/` — Terraform構成本体を置く専用フォルダ。
  - `versions.tf`, `provider.tf` — Terraform/プロバイダーの設定。
  - `connectors.tf` — `elasticstack_kibana_action_connector` リソース。
  - `rules.tf` — `elasticstack_kibana_alerting_rule` リソース。
  - `workflows.tf` — `elasticstack_kibana_agentbuilder_workflow` リソース。
- `terraform/scripts/list-kibana-resources.sh` — importするIDを調べるために、既存のconnector/rule/workflowを一覧表示するスクリプト。
- `terraform/Dockerfile` — Terraform CLI・jq・gitを入れたUBI10ベースのコンテナイメージ。
  `terraform/kibana/`の`.tf`ファイルと`terraform/scripts/`を`/workspace`に同梱しているので、
  単体でも動作する。OpenShiftのrestricted SCC(ランダムなUID、グループは常に0)で
  実行できるように、`/workspace`の所有グループをrootにしてグループ書き込み権限を
  付与し、`$HOME`も書き込み可能な`/workspace`にしている
  (`.github/workflows/build-and-push.yml`でGHCRにビルド&プッシュ)。
- `charts/tf-work/` — 上記のコンテナイメージを`replicas: 1`のStatefulSetとして
  OpenShift/Kubernetes上にデプロイするHelm Chart。詳細は
  [charts/tf-work/README.md](charts/tf-work/README.md)を参照。

固定のENTRYPOINTは設定していないので、コンテナ内で任意のコマンドを実行できる。

## 環境変数一覧

Pod内で設定が必要な環境変数はこれで全部。

| 環境変数 | 必須/任意 | 用途 |
| --- | --- | --- |
| `KIBANA_ENDPOINT` | 必須 | Kibanaの接続先URL。terraformプロバイダーと`list-kibana-resources.sh`の両方で使う。 |
| `KIBANA_API_KEY` | 認証方法として必須(下と排他) | APIキー認証。 |
| `KIBANA_USERNAME` / `KIBANA_PASSWORD` | 認証方法として必須(上と排他) | BASIC認証。`KIBANA_API_KEY`の代わりに使う。 |
| `KIBANA_INSECURE` | 任意(既定`false`) | `true`にすると`list-kibana-resources.sh`実行時にTLS証明書の検証をスキップする(`curl -k`相当)。 |
| `TF_VAR_kibana_insecure` | 任意(既定`false`) | `true`にすると`terraform`実行時にTLS証明書の検証をスキップする。仕組みが別なので、両方スキップしたい場合は`KIBANA_INSECURE`と両方設定する。 |

これらはPodに`oc set env`やSecret経由で設定する(下記「セットアップ」参照)。
`KIBANA_API_KEY`/`KIBANA_USERNAME`/`KIBANA_PASSWORD`はSecretに入れることを推奨する。

## セットアップ

OpenShiftはホストディレクトリのbind mountに対応していないため、リポジトリの
内容はPodとの間で`oc rsync`を使って同期する。まず、作業用に落とさずに
起動し続けるPodを1つ立てる。

```sh
oc run kibana-tf --image=ghcr.io/<owner>/kibana-tf:latest \
  --restart=Never \
  --command -- sleep infinity
```

ローカルの最新の内容(コミット前の変更も含む)をPodに反映する。

```sh
oc rsync ./ kibana-tf:/workspace --exclude=.git --exclude=.terraform
```

Kibanaへの接続情報は、Secretとして作成してPodに注入するのが望ましい。

```sh
oc create secret generic kibana-tf-credentials \
  --from-literal=KIBANA_ENDPOINT=https://my-kibana.example.com:5601 \
  --from-literal=KIBANA_API_KEY=...

oc set env pod/kibana-tf --from=secret/kibana-tf-credentials
```

BASIC認証や、TLS証明書の検証をスキップする設定(自己署名証明書など)も
必要であれば、上の「環境変数一覧」を参照して同様にSecret/`oc set env`で設定する。

Pod内のシェルに入り、`terraform/kibana`ディレクトリに移動して初期化する。

```sh
oc rsh kibana-tf
cd terraform/kibana
terraform init
```

## 既存リソースをTerraform管理下に置く手順

(Pod内のシェル、`terraform/kibana`ディレクトリで作業する)

1. 対象リソースのIDを調べる。
   ```sh
   ../scripts/list-kibana-resources.sh
   ```
2. 該当するファイル(`connectors.tf`、`rules.tf`、`workflows.tf`)に、そのIDを
   指定した`import`ブロックを追記する。ホスト側のエディタで編集する場合は、
   一旦Podのシェルを抜けて編集し、`oc rsync ./ kibana-tf:/workspace --exclude=.git --exclude=.terraform`
   で再度Podに反映してからPodに戻る。
3. 実在するKibanaリソースからリソース定義を自動生成する
   (`<type>`は追記したリソースの種類。connectorなら`connectors`、
   ruleなら`rules`、workflowなら`workflows`)。
   ```sh
   terraform plan -generate-config-out=generated_<type>.tf
   ```
4. 生成されたブロックを確認し、対応する`.tf`ファイルに取り込む
   (`secrets`/`secrets_wo`はKibanaから取得できないため手動で補完する)。
   その後`generated_*.tf`を削除し、`terraform plan`を再実行して差分が無いことを確認する。
5. Pod内の変更をホストに戻し、通常どおりgitでコミットする。
   ```sh
   oc rsync kibana-tf:/workspace ./ --exclude=.git
   ```
6. 作業が終わったらPodを削除する。
   ```sh
   oc delete pod kibana-tf
   ```

## 個別コマンドを直接実行する場合

Podを立てっぱなしにせず、コマンドを1回だけ実行して結果だけ見ることもできる
(この場合、コンテナ内に同梱された`.tf`ファイル・スクリプトが使われ、
変更はPod終了時に失われるので、リソースのimport作業には向かない)。

```sh
# terraformコマンドを直接実行
oc run kibana-tf-oneshot --rm -it \
  --image=ghcr.io/<owner>/kibana-tf:latest \
  --restart=Never \
  --env=KIBANA_ENDPOINT=... --env=KIBANA_API_KEY=... \
  --command -- terraform plan

# ヘルパースクリプトを実行
oc run kibana-tf-oneshot --rm -it \
  --image=ghcr.io/<owner>/kibana-tf:latest \
  --restart=Never \
  --env=KIBANA_ENDPOINT=... --env=KIBANA_API_KEY=... \
  --command -- ./scripts/list-kibana-resources.sh
```
