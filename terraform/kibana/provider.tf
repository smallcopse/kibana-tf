provider "elasticstack" {
  kibana {
    # 環境変数で設定する。APIキー認証の場合:
    #   KIBANA_ENDPOINT   例: https://my-kibana.example.com:5601
    #   KIBANA_API_KEY    connector/alerting rule/workflowを管理できる
    #                     権限を持つKibana APIキー
    #
    # ...APIキーの代わりにBasic認証を使う場合:
    #   KIBANA_USERNAME
    #   KIBANA_PASSWORD

    # TLS証明書の検証をスキップするかどうか(insecureはプロバイダーの
    # 環境変数に対応が無いため、ここで明示的に指定する必要がある)。
    # 有効にする場合は変数kibana_insecureをtrueにする
    # (例: TF_VAR_kibana_insecure=true、または -var=kibana_insecure=true)。
    insecure = var.kibana_insecure
  }
}
