# 既存のKibana action connectorをここにimportする。
#
# 手順:
#   1. ../scripts/list-kibana-resources.sh を実行して、Terraform管理下に置きたい
#      connectorのconnector_idを調べる。
#   2. 下に`import`ブロックを追記する。idは`<space_id>/<connector_id>`の形式で、
#      defaultスペースのみを管理するので "default/<connector_id>" になる。
#   3. 以下を実行する:
#        terraform plan -generate-config-out=generated_connectors.tf
#      これにより`elasticstack_kibana_action_connector`のリソースブロックが
#      generated_connectors.tfに自動生成される。
#   4. 生成された内容を確認し、必要ならリソースブロックをこのファイルに
#      移動・リネームしてから generated_connectors.tf を削除し、
#      `terraform plan`を再実行して差分が無いことを確認する。
#   5. secretsはKibanaから読み戻せないため、生成された設定の`secrets`属性は
#      手動で埋める(または`secrets_wo`にTerraform管理の値を設定する)必要がある。
#
# connectorが複数ある場合は、1つのimportブロック=1つのconnectorとして、
# それぞれ別のリソースラベル(`to =`の後ろの名前。ファイル内で重複不可)を
# 付けて並べる。ラベルはKibana上の名前と一致させなくてよい(自由に命名可)。
#
# import {
#   to = elasticstack_kibana_action_connector.slack
#   id = "default/<slack_connector_id>"
# }
#
# import {
#   to = elasticstack_kibana_action_connector.email
#   id = "default/<email_connector_id>"
# }
#
# この状態で`terraform plan -generate-config-out=generated_connectors.tf`を
# 実行すると、`slack`・`email`それぞれのリソースブロックが1つのファイルに
# まとめて生成される。生成後は必要に応じて`connectors.tf`本体に統合すればよい。
