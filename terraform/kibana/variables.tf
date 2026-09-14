variable "kibana_insecure" {
  description = "trueにするとKibana接続時にTLS証明書の検証をスキップする(自己署名証明書など)。既定はfalseで、必要な場合のみ明示的に有効化する。"
  type        = bool
  default     = false
}
