#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
用法: $(basename "$0") [-u <GitLab地址> -p <项目ID> -n <包名> -v <版本号> -t <扩展名> ...] <文件或文件夹路径>...

扫描并上传文件到 GitLab Package Registry
8.3 短文件名按以下规则还原：
  在同目录 .asm/.s 源文件名中，找 stem 以短名前缀开头者，取最短候选，
  输出 <stem>.<原扩展名大写>；找不到则原样保留短名

可选参数:
  -u  GitLab 地址，例如 https://git.tongji.edu.cn
  -p  项目 ID（数字）或 URL 编码后的项目路径（如 group%2Fproject）
  -n  包名（字母、数字、点、连字符、下划线，默认取所在目录名）
  -v  版本号（默认为 CalVer，如 2026.10.16）
  -t  扫描目录时的目标扩展名，逗号分隔，默认 exe（如 -t exe,elf）
  -r  上传后在仓库中显示的文件名（仅单文件模式生效）
  -k  跳过 SSL 证书校验（自签名证书时使用）
  -h  显示本帮助

Token 通过环境变量传入:
  export GITLAB_TOKEN=<个人访问令牌>

示例:
  export GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
  $(basename "$0") ./<作业号>_<作业名>/
  $(basename "$0") ./<作业号>_<作业名>/[<子任务号>_]<子任务名>.EXE
EOF
}

TARGETS=()
GITLAB_URL="https://git.tongji.edu.cn"
PROJECT_ID="1607"
PKG_NAME=""
PKG_VERSION="$(date +%Y.%m.%d)"
REMOTE_NAME=""
INSECURE=0
TARGET_EXT="exe"

while getopts ":f:u:p:n:v:r:t:kh" opt; do
  case "$opt" in
    f) TARGETS+=("$OPTARG") ;;
    u) GITLAB_URL="$OPTARG" ;;
    p) PROJECT_ID="$OPTARG" ;;
    n) PKG_NAME="$OPTARG" ;;
    v) PKG_VERSION="$OPTARG" ;;
    r) REMOTE_NAME="$OPTARG" ;;
    t) TARGET_EXT="$OPTARG" ;;
    k) INSECURE=1 ;;
    h) usage; exit 0 ;;
    \?) echo "错误: 未知参数 -$OPTARG" >&2; usage; exit 1 ;;
    :)  echo "错误: 参数 -$OPTARG 需要值" >&2; usage; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
TARGETS+=("$@")

[[ ${#TARGETS[@]} -gt 0 ]] || { echo "错误: 缺少文件或文件夹路径参数" >&2; usage; exit 1; }
[[ -n "${GITLAB_TOKEN:-}" ]] || { echo "错误: 请先导出 GITLAB_TOKEN 环境变量" >&2; exit 1; }
GITLAB_URL="${GITLAB_URL%/}"

lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }
upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
is_all_caps() { [[ "$1" =~ [A-Z] && ! "$1" =~ [a-z] ]]; }
sanitize_pkg_name() { echo "$1" | tr ' ' '-' | tr -cd '[:alnum:]._-'; }

is_short_name() {
  local name="$1" ext="$2"
  [[ "$(lower "$name")" =~ ^([^~]*)~[0-9]+\.${ext}$ ]]
}

short_name_prefix() {
  local n; n="$(lower "$1")"
  local ext="$2"
  [[ "$n" =~ ^([^~]*)~[0-9]+\.${ext}$ ]] && echo "${BASH_REMATCH[1]}"
}

strip_asm_ext() {
  local n="$1"
  case "$(lower "$n")" in
    *.asm) echo "${n:0:${#n}-4}" ;;
    *.s)   echo "${n:0:${#n}-2}" ;;
    *)     echo "$n" ;;
  esac
}

resolve_short_name() {
  local short="$1" ext="$2"; shift 2
  local prefix; prefix="$(short_name_prefix "$short" "$ext")"
  [[ -z "$prefix" ]] && return 1
  local best="" a stem
  for a in "$@"; do
    stem="$(strip_asm_ext "$a")"
    if [[ "$(lower "$stem")" == "$prefix"* ]] && { [[ -z "$best" ]] || (( ${#stem} < ${#best} )); }; then
      best="$stem"
    fi
  done
  [[ -z "$best" ]] && return 1
  echo "$(upper "$best").$(upper "$ext")"
}

corrected_file_part() {
  local base="$1" ext="$2"; shift 2
  local fixed
  if is_short_name "$base" "$ext" && fixed="$(resolve_short_name "$base" "$ext" "$@")"; then
    echo "$fixed"
  else
    echo "$base"
  fi
}

build_remote_name() {
  local base="$1" pkg="$2"; shift 2
  local ext="${base##*.}"
  ext="$(lower "$ext")"
  local corrected; corrected="$(corrected_file_part "$base" "$ext" "$@")"
  if is_all_caps "$corrected"; then
    echo "$(upper "$pkg")_${corrected}"
  else
    echo "${pkg}_${corrected}"
  fi
}

FILES=()
ASM_FILES=()
FOLDER_NAME=""

IFS=',' read -r -a EXT_LIST <<< "$TARGET_EXT"
[[ ${#EXT_LIST[@]} -gt 0 ]] || EXT_LIST=("exe")

for t in "${TARGETS[@]}"; do
  if [[ -d "$t" ]]; then
    dir="$(cd "$t" && pwd)"
    [[ -z "$FOLDER_NAME" ]] && FOLDER_NAME="$(basename "$dir")"
    for e in "${EXT_LIST[@]}"; do
      e="$(lower "$e")"
      [[ -n "$e" ]] || continue
      while IFS= read -r -d '' f; do FILES+=("$f"); done \
        < <(find "$dir" -maxdepth 1 -type f -iname "*.${e}" -print0)
    done
  elif [[ -f "$t" ]]; then
    dir="$(cd "$(dirname "$t")" && pwd)"
    FILES+=("$dir/$(basename "$t")")
    [[ -z "$FOLDER_NAME" ]] && FOLDER_NAME="$(basename "$dir")"
  else
    echo "错误: 路径不存在: $t" >&2; exit 1
  fi

  while IFS= read -r -d '' f; do ASM_FILES+=("$(basename "$f")"); done \
    < <(find "$dir" -maxdepth 1 -type f \( -iname '*.asm' -o -iname '*.s' \) -print0)
done

[[ ${#FILES[@]} -gt 0 ]] || { echo "错误: 未找到可上传文件" >&2; exit 1; }

if [[ ${#ASM_FILES[@]} -gt 0 ]]; then
  DEDUP=()
  while IFS= read -r line; do [[ -n "$line" ]] && DEDUP+=("$line"); done \
    < <(printf '%s\n' "${ASM_FILES[@]}" | sort -u)
  ASM_FILES=("${DEDUP[@]}")
fi

SORTED=()
while IFS= read -r line; do [[ -n "$line" ]] && SORTED+=("$line"); done \
  < <(printf '%s\n' "${FILES[@]}" | sort -r -f)
FILES=("${SORTED[@]}")

[[ -n "$PKG_NAME" ]] || PKG_NAME="$FOLDER_NAME"
PKG_NAME="$(sanitize_pkg_name "$PKG_NAME")"
[[ -n "$PKG_NAME" ]] || { echo "错误: 包名为空（净化后）" >&2; exit 1; }

if [[ ${#FILES[@]} -eq 1 && -z "$REMOTE_NAME" ]]; then
  REMOTE_NAME="$(build_remote_name "$(basename "${FILES[0]}")" "$PKG_NAME" "${ASM_FILES[@]}")"
fi

echo "==> 包名: $PKG_NAME"
echo "==> 版本: $PKG_VERSION"
echo "==> 待上传 ${#FILES[@]} 个文件"

TOTAL=${#FILES[@]}
OK=0; FAIL=0; ERRORS=()

for idx in "${!FILES[@]}"; do
  FILE="${FILES[$idx]}"
  BASE="$(basename "$FILE")"
  if [[ "$TOTAL" -eq 1 && -n "$REMOTE_NAME" ]]; then
    REMOTE="$REMOTE_NAME"
  else
    REMOTE="$(build_remote_name "$BASE" "$PKG_NAME" "${ASM_FILES[@]}")"
  fi

  UPLOAD_URL="${GITLAB_URL}/api/v4/projects/${PROJECT_ID}/packages/generic/${PKG_NAME}/${PKG_VERSION}/${REMOTE}"
  echo "[$((idx+1))/${TOTAL}] $BASE -> $REMOTE"
  echo "        $UPLOAD_URL"

  CURL_OPTS=(--location --fail --show-error --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" --upload-file "$FILE")
  [[ "$INSECURE" -eq 1 ]] && CURL_OPTS+=(--insecure)
  RESP_FILE="$(mktemp)"
  HTTP_CODE=$(curl "${CURL_OPTS[@]}" --write-out "%{http_code}" --output "$RESP_FILE" "$UPLOAD_URL" 2>/dev/null || true)

  if [[ "$HTTP_CODE" == "201" ]]; then
    OK=$((OK+1)); echo "        ✓ 成功 (HTTP 201)"
  else
    FAIL=$((FAIL+1)); ERRORS+=("${REMOTE}: HTTP ${HTTP_CODE} - $(head -c 200 "$RESP_FILE" 2>/dev/null || true)")
    echo "        ✗ 失败 (HTTP ${HTTP_CODE})" >&2; cat "$RESP_FILE" >&2 || true; echo >&2
  fi
  rm -f "$RESP_FILE"
done

echo
if [[ "$FAIL" -eq 0 ]]; then
  echo "==> 全部上传成功，共 ${OK} 个文件"
else
  echo "==> 上传完成：成功 ${OK}，失败 ${FAIL}" >&2
  for e in "${ERRORS[@]:0:3}"; do echo "    $e" >&2; done
  [[ ${#ERRORS[@]} -gt 3 ]] && echo "    ..." >&2
  exit 1
fi
