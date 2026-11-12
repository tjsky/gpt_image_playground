#!/bin/sh

# 生成 /etc/nginx/relay/ 下的站点代理配置片段（在 20-envsubst 之前执行）。
# 两个文件都支持管理员直接挂载覆盖，挂载后本脚本不会重写。

RELAY_DIR=/etc/nginx/relay
mkdir -p "$RELAY_DIR"

escape_nginx() {
    # 转义 nginx 双引号字符串中的特殊字符
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g'
}

trim() {
    printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

API_PROXY_URL_VALUE=$(trim "${API_PROXY_URL:-}")
API_PROXY_KEY_VALUE="${API_PROXY_KEY:-}"

# ---- 1. 真实上游地址与真实 KEY ----
if [ ! -f "$RELAY_DIR/api-target.conf" ]; then
    if [ -z "$API_PROXY_URL_VALUE" ] || [ -z "$API_PROXY_KEY_VALUE" ]; then
        if [ "${ENABLE_API_PROXY:-false}" = "true" ]; then
            echo "错误：ENABLE_API_PROXY=true，但缺少 API_PROXY_URL / API_PROXY_KEY，且未挂载 $RELAY_DIR/api-target.conf" >&2
            exit 1
        fi
        cat > "$RELAY_DIR/api-target.conf" <<'EOF'
# 未启用站点 API 代理：未设置 API_PROXY_URL / API_PROXY_KEY，也没有挂载自定义配置
EOF
    else
        case "$API_PROXY_URL_VALUE" in
            */) RELAY_TARGET="$API_PROXY_URL_VALUE" ;;
            *) RELAY_TARGET="$API_PROXY_URL_VALUE/" ;;
        esac
        RELAY_TARGET_ESCAPED=$(escape_nginx "$RELAY_TARGET")
        RELAY_KEY_ESCAPED=$(escape_nginx "$API_PROXY_KEY_VALUE")
        cat > "$RELAY_DIR/api-target.conf" <<EOF
# 由容器启动脚本根据 API_PROXY_URL / API_PROXY_KEY 生成；挂载同名文件可覆盖本文件
proxy_pass $RELAY_TARGET_ESCAPED;
proxy_set_header Authorization "Bearer $RELAY_KEY_ESCAPED";
proxy_hide_header Server;
EOF
        chmod 600 "$RELAY_DIR/api-target.conf"
        echo "站点 API 代理已配置：上游 $RELAY_TARGET（真实 KEY 仅存在于本文件，不会进入前端产物）"
    fi
fi

# ---- 2. 图片代理域名白名单 ----
if [ ! -f "$RELAY_DIR/image-allow.conf" ]; then
    IMAGE_HOSTS=$(trim "${IMAGE_PROXY_ALLOW_HOSTS:-}")
    if [ -n "$IMAGE_HOSTS" ]; then
        IMAGE_HOSTS_PATTERN=$(printf '%s' "$IMAGE_HOSTS" | sed -e 's/[[:space:]]//g' -e 's/,/|/g')
        cat > "$RELAY_DIR/image-allow.conf" <<EOF
# 由 IMAGE_PROXY_ALLOW_HOSTS 生成（默认只拦截非 https 与内网地址）
if (\$arg_url !~* "^https://([A-Za-z0-9-]+\.)*($IMAGE_HOSTS_PATTERN)/") {
    return 403 "Image host not allowed";
}
EOF
        echo "图片代理域名白名单：$IMAGE_HOSTS"
    else
        cat > "$RELAY_DIR/image-allow.conf" <<'EOF'
# 未设置 IMAGE_PROXY_ALLOW_HOSTS：仅依赖模板内置的 https + 内网地址拦截。
# 生产环境建议设置该变量或挂载本文件，把可代理的图片域名收敛到中转站自己的 CDN。
EOF
        echo "提示：未设置 IMAGE_PROXY_ALLOW_HOSTS，图片代理仅拦截非 https 与内网地址。建议收敛白名单。" >&2
    fi
fi
