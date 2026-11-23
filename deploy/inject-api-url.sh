#!/bin/sh

# 用环境变量替换前端默认 API URL。显式传入空字符串时保留为空。
if [ "${DEFAULT_API_URL+x}" != "x" ]; then
    DEFAULT_API_URL=${API_URL:-https://api.openai.com/v1}
fi
DOCKER_LEGACY_API_URL_USED=${DOCKER_LEGACY_API_URL_USED:-false}
if [ -n "$API_URL" ]; then
    DOCKER_LEGACY_API_URL_USED=true
fi

API_PROXY_AVAILABLE=false
if [ "$ENABLE_API_PROXY" = "true" ]; then
    API_PROXY_AVAILABLE=true
fi

API_PROXY_LOCKED=false
if [ "$ENABLE_API_PROXY" = "true" ] && [ "$LOCK_API_PROXY" = "true" ]; then
    API_PROXY_LOCKED=true
fi

PRESET_CONFIG_ONLY=false
if [ "$SHOW_PRESET_CONFIG_ONLY" = "true" ] || [ "$SHOW_DEFAULT_CONFIG_ONLY" = "true" ]; then
    PRESET_CONFIG_ONLY=true
fi

CONFIG_CHANGE_DIALOG=true
if [ "$SHOW_CONFIG_CHANGE_DIALOG" = "false" ]; then
    CONFIG_CHANGE_DIALOG=false
fi

PRESET_CONFIG_PARAMS_LOCKED=false
if [ "$LOCK_PRESET_CONFIG_PARAMS" = "true" ]; then
    PRESET_CONFIG_PARAMS_LOCKED=true
fi

PRESET_CONFIG_DELETION_PREVENTED=false
if [ "$PREVENT_PRESET_CONFIG_DELETION" = "true" ]; then
    PRESET_CONFIG_DELETION_PREVENTED=true
fi

escape_sed_replacement() {
    printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}

escape_js_string() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

DEFAULT_API_URL_TRIMMED=$(printf '%s' "$DEFAULT_API_URL" | sed 's/^[[:space:]]*//')
case "$DEFAULT_API_URL_TRIMMED" in
    http://*|https://*)
        DEFAULT_CONFIG_URL_PATH=${DEFAULT_API_URL_TRIMMED%%\?*}
        DEFAULT_CONFIG_URL_PATH=${DEFAULT_CONFIG_URL_PATH%%\#*}
        DEFAULT_CONFIG_URL_PATH_LOWER=$(printf '%s' "$DEFAULT_CONFIG_URL_PATH" | tr '[:upper:]' '[:lower:]')
        case "$DEFAULT_CONFIG_URL_PATH_LOWER" in
            *.json)
                if ! DEFAULT_CONFIG_JSON=$(wget -qO- "$DEFAULT_API_URL_TRIMMED"); then
                    echo "预置配置请求失败：$DEFAULT_API_URL_TRIMMED" >&2
                    exit 1
                fi
                DEFAULT_API_URL="embedded-config:$(printf '%s' "$DEFAULT_CONFIG_JSON" | base64 | tr -d '\n')"
                ;;
        esac
        ;;
    file://*)
        DEFAULT_CONFIG_PATH=${DEFAULT_API_URL_TRIMMED#file://}
        if [ ! -f "$DEFAULT_CONFIG_PATH" ]; then
            echo "预置配置文件不存在：$DEFAULT_CONFIG_PATH" >&2
            exit 1
        fi
        DEFAULT_API_URL="embedded-config:$(base64 < "$DEFAULT_CONFIG_PATH" | tr -d '\n')"
        ;;
    *)
        if [ -f "$DEFAULT_API_URL_TRIMMED" ]; then
            DEFAULT_API_URL="embedded-config:$(base64 < "$DEFAULT_API_URL_TRIMMED" | tr -d '\n')"
        else
            case "$DEFAULT_API_URL_TRIMMED" in
                *.json)
                    echo "预置配置文件不存在：$DEFAULT_API_URL_TRIMMED" >&2
                    exit 1
                    ;;
            esac
        fi
        ;;
esac
DEFAULT_API_URL_ESCAPED=$(escape_sed_replacement "$(escape_js_string "$DEFAULT_API_URL")")
# 默认字体：builtin / system，其他值视为字体名称；留空时前端按 builtin 处理
DEFAULT_UI_FONT_ESCAPED=$(escape_sed_replacement "$(escape_js_string "$DEFAULT_UI_FONT")")
DEFAULT_MONO_FONT_ESCAPED=$(escape_sed_replacement "$(escape_js_string "$DEFAULT_MONO_FONT")")
# 内置字体加载来源：local（本站）/ cdn（公共 CDN）；留空时为 cdn
BUILTIN_FONT_SOURCE_ESCAPED=$(escape_sed_replacement "$(escape_js_string "$BUILTIN_FONT_SOURCE")")
# 前端持有的「假 KEY」：只在 Nginx 侧校验用，泄露也无价值；真实 KEY 由 deploy/10-relay-conf.sh 注入
DEFAULT_API_KEY_ESCAPED=$(escape_sed_replacement "$(escape_js_string "$DEFAULT_API_KEY")")
# 默认生图模型与模型注释（形如 `模型名=注释;模型名=注释`，模型名不区分大小写）
DEFAULT_IMAGE_MODEL_ESCAPED=$(escape_sed_replacement "$(escape_js_string "${DEFAULT_IMAGE_MODEL:-}")")
IMAGE_MODEL_NOTES_ESCAPED=$(escape_sed_replacement "$(escape_js_string "${IMAGE_MODEL_NOTES:-}")")
# 预置文本配置的模型名（留空则不创建文本配置，Agent 需用户手动配置）
DEFAULT_TEXT_MODEL_ESCAPED=$(escape_sed_replacement "$(escape_js_string "${DEFAULT_TEXT_MODEL:-}")")
DEFAULT_TEXT_MODEL_NAME_ESCAPED=$(escape_sed_replacement "$(escape_js_string "${DEFAULT_TEXT_MODEL_NAME:-}")")

# 查找所有 js 文件并将占位符替换为运行时配置
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DEFAULT_API_URL_PLACEHOLDER__|$DEFAULT_API_URL_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DEFAULT_API_KEY_PLACEHOLDER__|$DEFAULT_API_KEY_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DEFAULT_IMAGE_MODEL_PLACEHOLDER__|$DEFAULT_IMAGE_MODEL_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_IMAGE_MODEL_NOTES_PLACEHOLDER__|$IMAGE_MODEL_NOTES_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DEFAULT_TEXT_MODEL_PLACEHOLDER__|$DEFAULT_TEXT_MODEL_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DEFAULT_TEXT_MODEL_NAME_PLACEHOLDER__|$DEFAULT_TEXT_MODEL_NAME_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_API_PROXY_AVAILABLE_PLACEHOLDER__|$API_PROXY_AVAILABLE|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_API_PROXY_LOCKED_PLACEHOLDER__|$API_PROXY_LOCKED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DOCKER_DEPLOYMENT_PLACEHOLDER__|true|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DOCKER_LEGACY_API_URL_USED_PLACEHOLDER__|$DOCKER_LEGACY_API_URL_USED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_SHOW_PRESET_CONFIG_ONLY_PLACEHOLDER__|$PRESET_CONFIG_ONLY|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_SHOW_CONFIG_CHANGE_DIALOG_PLACEHOLDER__|$CONFIG_CHANGE_DIALOG|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_LOCK_PRESET_CONFIG_PARAMS_PLACEHOLDER__|$PRESET_CONFIG_PARAMS_LOCKED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_PREVENT_PRESET_CONFIG_DELETION_PLACEHOLDER__|$PRESET_CONFIG_DELETION_PREVENTED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DEFAULT_UI_FONT_PLACEHOLDER__|$DEFAULT_UI_FONT_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_DEFAULT_MONO_FONT_PLACEHOLDER__|$DEFAULT_MONO_FONT_ESCAPED|g" {} +
find /usr/share/nginx/html/assets -type f -name "*.js" -exec sed -i "s|__VITE_BUILTIN_FONT_SOURCE_PLACEHOLDER__|$BUILTIN_FONT_SOURCE_ESCAPED|g" {} +

# 检查是否启用了 API 代理
if [ "$ENABLE_API_PROXY" != "true" ]; then
    # 删除代理配置块
    sed -i '/# BEGIN API PROXY/,/# END API PROXY/d' /etc/nginx/conf.d/default.conf
fi

# 未配置假 KEY 时必须去掉校验，否则整站代理请求全被 401（同时告警，说明代理处于敞开状态）
if [ -z "$DEFAULT_API_KEY" ]; then
    sed -i '/# BEGIN KEY CHECK/,/# END KEY CHECK/d' /etc/nginx/conf.d/default.conf
    if [ "$ENABLE_API_PROXY" = "true" ]; then
        echo "警告：未设置 DEFAULT_API_KEY，已关闭代理假 KEY 校验，任何访问者都可调用本站代理额度" >&2
    fi
fi

exec "$@"
