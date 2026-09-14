FROM redhat/ubi10-minimal:latest

ARG TERRAFORM_VERSION=1.16.2
ARG TARGETARCH

# unzip: Terraformのリリースアーカイブを展開するために使用
# jq: terraform/scripts/list-kibana-resources.sh でKibana APIの応答を
#     パースするために使用
# git: TerraformのモジュールやプロバイダーをVCSから取得するために使用
# (curl・bash・coreutilsはubi-minimalイメージに標準で入っている)
RUN microdnf install -y unzip jq git ca-certificates && microdnf clean all

WORKDIR /tmp

# Terraformをダウンロードし、HashiCorp公式のチェックサムで検証する。
# sha256sum -c はSHA256SUMSに書かれた元のファイル名と同名のファイルが
# カレントディレクトリに存在することを前提にするため、-oで別名保存せず
# 元のファイル名のままダウンロードする
RUN terraform_zip="terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" \
    && curl -fsSL -O "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${terraform_zip}" \
    && curl -fsSL -o terraform_SHA256SUMS "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
    && grep "${terraform_zip}" terraform_SHA256SUMS | sha256sum -c - \
    && unzip "${terraform_zip}" -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm -f "${terraform_zip}" terraform_SHA256SUMS

# バイナリの展開が終わったのでunzipは削除する
RUN microdnf remove -y unzip && microdnf clean all

WORKDIR /workspace

# このリポジトリの.tfファイルとヘルパースクリプトをイメージに同梱し、
# ボリュームマウント無しでもコンテナ単体でterraformやスクリプトを
# 実行できるようにする
COPY terraform/kibana/*.tf ./
COPY terraform/scripts/ ./scripts/
RUN chmod +x scripts/*.sh

# OpenShiftの restricted SCC で実行される前提の対応。
# restricted SCCではDockerfileのUSERは無視され、プロジェクトごとに割り当てられた
# 範囲からランダムなUIDでコンテナが実行される。どのUID・グループで実行されても
# /workspace配下に自由にファイルを置けるよう、777(誰でも読み書き実行可)にしておく。
RUN chmod -R 777 /workspace

# 任意UIDには/etc/passwdのエントリが無く$HOMEが未設定・書き込み不可になるため、
# 書き込み可能な/workspaceを$HOMEにする
# (Terraformのプラグインキャッシュやgitの設定の書き込み先として必要)
ENV HOME=/workspace

# 非rootユーザーで実行する(OpenShift以外でdocker run等で使う場合の
# デフォルト。OpenShiftのrestricted SCC下では実際にはこのUIDではなく
# ランダムなUIDに上書きされる)
USER 1001

# ENTRYPOINTは固定せず、イメージ内で任意のコマンドを実行できるようにする。例:
#   oc run --rm -it kibana-tf --image=<image> --command -- bash   -> 対話シェル
#   oc run --rm kibana-tf --image=<image> --command -- terraform plan
#   oc run --rm kibana-tf --image=<image> --command -- ./scripts/list-kibana-resources.sh
CMD ["bash"]
