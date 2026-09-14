# tf-work

`terraform/Dockerfile`でビルドしたTerraform作業用コンテナイメージを、
`replicas: 1`のStatefulSetとして動かすためのHelm Chart。

## デプロイ

```sh
helm install tf-work ./charts/tf-work \
  --set kibana.endpoint=https://my-kibana.example.com:5601 \
  --set kibana.apiKey=...
```

BASIC認証(username/password)の場合:

```sh
helm install tf-work ./charts/tf-work \
  --set kibana.endpoint=https://my-kibana.example.com:5601 \
  --set kibana.username=elastic \
  --set kibana.password=...
```

既存のSecretを使う場合(`KIBANA_ENDPOINT`・`KIBANA_API_KEY`または
`KIBANA_USERNAME`/`KIBANA_PASSWORD`をキーに持つSecretを事前に作成しておく):

```sh
helm install tf-work ./charts/tf-work \
  --set kibana.existingSecret=kibana-tf-credentials
```

## 使い方

```sh
kubectl exec -it tf-work-0 -- bash          # OpenShiftなら oc rsh tf-work-0
kubectl cp ./ tf-work-0:/workspace          # OpenShiftなら oc rsync ./ tf-work-0:/workspace --exclude=.git --exclude=.terraform
```

詳しい作業手順(importブロックの追記など)はリポジトリルートの[README.md](../../README.md)を参照。

主なvalues:

| キー | 説明 | デフォルト |
| --- | --- | --- |
| `image.repository` / `image.tag` | 使用するコンテナイメージ | `ghcr.io/smallcopse/kibana-tf` / `latest` |
| `replicaCount` | レプリカ数 | `1` |
| `kibana.existingSecret` | Kibana接続情報を持つ既存Secret名 | `""` |
| `kibana.endpoint` / `kibana.apiKey` / `kibana.username` / `kibana.password` | 既存Secretを使わない場合にChart側で作成するSecretの内容 | `""` |
