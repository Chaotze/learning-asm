#!/usr/bin/env bash
set -euo pipefail

# ---------- 用法 ----------
usage() {
  cat <<EOF
用法: $(basename "$0") [-u <GitLab地址> -p <项目ID> -n <包名> -v <版本号> ...] <文件路径>

可选参数:
  -u  GitLab 地址，例如 https://git.tongji.edu.cn
  -p  项目 ID（数字）或 URL 编码后的项目路径（如 group%2Fproject）
  -n  包名（字母、数字、点、连字符、下划线，默认取所在目录名）
  -v  版本号（默认为 CalVer，如 2026.10.16）
  -r  上传后在仓库中显示的文件名（默认取所在目录名_本地文件名）
  -k  跳过 SSL 证书校验（自签名证书时使用）
  -h  显示本帮助

Token 通过环境变量传入:
  export GITLAB_TOKEN=<个人访问令牌>

示例:
  export GITLAB_TOKEN=glpat-xxxxxxxx
  $(basename "$0") -f ./<作业号>_<作业名>/[<子任务号>_]<子任务名>.EXE
EOF
}

# ---------- 默认值 ----------
FILE=""
GITLAB_URL="https://git.tongji.edu.cn"
PROJECT_ID="1607"
PKG_NAME=""
PKG_VERSION="$(date +%Y.%m.%d)"
REMOTE_NAME=""
INSECURE=0

# ---------- 解析参数 ----------
while getopts ":f:u:p:n:v:r:kh" opt; do
  case "$opt" in
    f) FILE="$OPTARG" ;;
    u) GITLAB_URL="$OPTARG" ;;
    p) PROJECT_ID="$OPTARG" ;;
    n) PKG_NAME="$OPTARG" ;;
    v) PKG_VERSION="$OPTARG" ;;
    r) REMOTE_NAME="$OPTARG" ;;
    k) INSECURE=1 ;;
    h) usage; exit 0 ;;
    \?) echo "错误: 未知参数 -$OPTARG" >&2; usage; exit 1 ;;
    :)  echo "错误: 参数 -$OPTARG 需要值" >&2; usage; exit 1 ;;
  esac
done

# 未通过 -f 指定时，从最后一个位置参数取文件路径
shift $((OPTIND - 1))
if [[ -z "$FILE" && $# -gt 0 ]]; then
  FILE="${!#}"
fi

# ---------- 校验 ----------
[[ -n "$FILE" ]]        || { echo "错误: 缺少文件路径参数" >&2; usage; exit 1; }
[[ -f "$FILE" ]]        || { echo "错误: 文件不存在: $FILE" >&2; exit 1; }
[[ -n "${GITLAB_TOKEN:-}" ]] || { echo "错误: 请先导出 GITLAB_TOKEN 环境变量" >&2; exit 1; }

# 去掉 URL 末尾的斜杠
GITLAB_URL="${GITLAB_URL%/}"

# 默认包名取所在目录名
[[ -z "$PKG_NAME" ]] && PKG_NAME="$(basename "$(cd "$(dirname "$FILE")" && pwd)")"

# 默认远端文件名取所在目录名_本地文件名
if [[ -z "$REMOTE_NAME" ]]; then
  FILENAME="$(basename "$FILE")"
  # 文件名全大写时，所在目录名部分也转全大写
  if [[ "$FILENAME" =~ [A-Z] && ! "$FILENAME" =~ [a-z] ]]; then
    REMOTE_NAME="$(echo "$PKG_NAME" | tr '[:lower:]' '[:upper:]')_${FILENAME}"
  else
    REMOTE_NAME="${PKG_NAME}_${FILENAME}"
  fi
fi

# 由于 GitLab 包名只允许字母、数字、点、连字符、下划线，加以净化
PKG_NAME="$(echo "$PKG_NAME" | tr ' ' '-' | tr -cd '[:alnum:]._-')"

# ---------- 构造上传地址 ----------
UPLOAD_URL="${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/packages/generic/${PKG_NAME}/${PKG_VERSION}/${REMOTE_NAME}"

echo "==> 上传文件: $FILE"
echo "==> 目标地址: $UPLOAD_URL"

# ---------- 执行上传 ----------
CURL_OPTS=(
  --location
  --fail
  --show-error
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}"
  --upload-file "$FILE"
)

[[ "$INSECURE" -eq 1 ]] && CURL_OPTS+=(--insecure)

HTTP_CODE=$(curl "${CURL_OPTS[@]}" \
  --write-out "%{http_code}" \
  --output /tmp/gitlab-upload-response.json \
  "$UPLOAD_URL" || true)

if [[ "$HTTP_CODE" == "201" ]]; then
  echo "==> 上传成功 (HTTP 201)"
else
  echo "==> 上传失败 (HTTP ${HTTP_CODE})" >&2
  echo "--- 服务端返回 ---" >&2
  cat /tmp/gitlab-upload-response.json >&2
  exit 1
fi

rm /tmp/gitlab-upload-response.json
