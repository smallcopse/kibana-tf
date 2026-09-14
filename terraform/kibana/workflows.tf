# 既存のKibana workflow(Agent Builder workflow)をここにimportする。
#
# 手順:
#   1. ../scripts/list-kibana-resources.sh を実行して、Terraform管理下に置きたい
#      workflowのworkflow_idを調べる。
#   2. 下に`import`ブロックを追記する。このリソースの`id`属性は
#      `<space_id>/<workflow_id>`と文書化されているので、defaultスペースなら
#      "default/<workflow_id>" になる。他のリソースと違い、プロバイダーの
#      公式ドキュメントにimport用idの形式が明記されていない(比較的新しい
#      リソースのため)ので、最初の1件をimportした際は`terraform plan`で
#      差分が出ないことを必ず確認してから残りに適用すること。
#   3. 以下を実行する:
#        terraform plan -generate-config-out=generated_workflows.tf
#      これにより`elasticstack_kibana_agentbuilder_workflow`のリソースブロックが
#      (`configuration_yaml`のheredocとして)generated_workflows.tfに自動生成される。
#   4. 生成された内容を確認し、必要ならリソースブロックをこのファイルに
#      移動・リネームしてから generated_workflows.tf を削除し、
#      `terraform plan`を再実行して差分が無いことを確認する。
#
# import {
#   to = elasticstack_kibana_agentbuilder_workflow.example
#   id = "default/<workflow_id>"
# }
