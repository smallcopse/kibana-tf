#!/usr/bin/env bash
# `import`ブロックに必要なidを調べるため、defaultスペースの既存の
# Kibana connector・alerting rule・workflowを一覧表示する。
#
# 必要なコマンド: curl, jq
# 必要な環境変数: KIBANA_ENDPOINT、および以下のいずれか
#   - KIBANA_API_KEY
#   - KIBANA_USERNAME と KIBANA_PASSWORD (Basic認証)
# (elasticstackプロバイダーと同じ環境変数)
# 任意の環境変数: KIBANA_INSECURE=true にするとTLS証明書の検証をスキップする
# (自己署名証明書など。elasticstackプロバイダー側のvar.kibana_insecureに対応)

set -euo pipefail

: "${KIBANA_ENDPOINT:?KIBANA_ENDPOINTを設定してください。例: https://my-kibana.example.com:5601}"

curl_auth_args=()
if [[ -n "${KIBANA_API_KEY:-}" ]]; then
  curl_auth_args=(-H "Authorization: ApiKey ${KIBANA_API_KEY}")
elif [[ -n "${KIBANA_USERNAME:-}" && -n "${KIBANA_PASSWORD:-}" ]]; then
  curl_auth_args=(-u "${KIBANA_USERNAME}:${KIBANA_PASSWORD}")
else
  echo "KIBANA_API_KEY、またはKIBANA_USERNAMEとKIBANA_PASSWORDの両方を設定してください" >&2
  exit 1
fi

if [[ "${KIBANA_INSECURE:-false}" == "true" ]]; then
  curl_auth_args+=(-k)
fi

echo "## Connectors (GET /api/actions/connectors)"
curl -fsS "${curl_auth_args[@]}" -H "kbn-xsrf: true" \
  "${KIBANA_ENDPOINT}/api/actions/connectors" \
  | jq -r '.[] | "\(.id)\t\(.connector_type_id)\t\(.name)"'

echo
echo "## Alerting rules (GET /api/alerting/rules/_find)"
curl -fsS "${curl_auth_args[@]}" -H "kbn-xsrf: true" \
  "${KIBANA_ENDPOINT}/api/alerting/rules/_find?per_page=100" \
  | jq -r '.data[] | "\(.id)\t\(.rule_type_id)\t\(.name)"'

echo
echo "## Workflows (GET /api/workflows)"
curl -fsS "${curl_auth_args[@]}" -H "kbn-xsrf: true" \
  "${KIBANA_ENDPOINT}/api/workflows?size=100" \
  | jq -r '.results[] | "\(.id)\t\(.name)"'
