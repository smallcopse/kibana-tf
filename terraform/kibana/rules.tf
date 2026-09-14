# 既存のKibana alerting ruleをここにimportする。
#
# 手順:
#   1. ../scripts/list-kibana-resources.sh を実行して、Terraform管理下に置きたい
#      ruleのrule_idを調べる。
#   2. 下に`import`ブロックを追記する。idは`<space_id>/<rule_id>`の形式で、
#      defaultスペースのみを管理するので "default/<rule_id>" になる。
#   3. 以下を実行する:
#        terraform plan -generate-config-out=generated_rules.tf
#      これにより`elasticstack_kibana_alerting_rule`のリソースブロックが
#      generated_rules.tfに自動生成される。
#   4. 生成された内容(特にconnectorを参照する`actions`)を確認し、必要なら
#      リソースブロックをこのファイルに移動・リネームしてから
#      generated_rules.tfを削除し、`terraform plan`を再実行して
#      差分が無いことを確認する。
#
# import {
#   to = elasticstack_kibana_alerting_rule.example
#   id = "default/<rule_id>"
# }
