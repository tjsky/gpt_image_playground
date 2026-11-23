# Docker 部署指南（站点 API 代理版）

面向「Docker Compose + Nginx / Cloudflare Access」的服务器部署。README 讲的是项目全貌，这份只讲怎么把这套代理跑起来、之后怎么改、怎么排错。

---

## 1. 部署前要准备什么

| 项 | 说明 |
| --- | --- |
| 服务器 | 能跑 Docker 的 Linux（amd64/arm64 均可） |
| 端口 | 容器内 80，宿主机映射一个未被占用的端口（本文用 `8080`） |
| 反向代理 | 已有的 Nginx 或 Cloudflare Tunnel 指向 `127.0.0.1:8080` |
| 访问控制 | **必须有**。Cloudflare Access / Nginx Basic Auth 二选一，见 §7 |
| 真实凭据 | 生图上游 URL + KEY；文本上游 URL + KEY（同一 KEY 也能生图文本时只填一组） |

> 代理对访客是「开箱即用」的：任何能打开站点的人都能消耗你的额度。访问控制不是可选项。

---

## 2. 目录结构

建议固定在一个目录，方便挂载和备份：

```
/opt/gpt-image-playground/
├── docker-compose.yml
├── .env                        # 假 KEY、预置模型名等非敏感配置
└── relay/
    ├── api-target.conf         # 真实上游 + 真实 KEY（chmod 600，绝不入 git）
    └── image-allow.conf        # 图片代理域名白名单（可留空）
```

---

## 3. 首次部署

### 3.1 写 `.env`

```bash
mkdir -p /opt/gpt-image-playground/relay
cd /opt/gpt-image-playground

cat > .env <<'EOF'
# 前端可见的「假」地址与「假」KEY：随便填，访客看到的就是这两个值
DEFAULT_API_URL=https://api.example.com/v1
DEFAULT_API_KEY=sk-fake-change-me

# 预置文本模型：设了访客开箱即用 Agent（混合模式已预选好），留空则不预置
# 默认生图模型与模型注释（只影响前端展示）
DEFAULT_IMAGE_MODEL=gpt-image-2.6-flare
IMAGE_MODEL_NOTES=gpt-image-2.6-sunburst=顶级模型;gpt-image-2.6-flare=正常模型，适合日常使用

DEFAULT_TEXT_MODEL=deepseek-flash
DEFAULT_TEXT_MODEL_NAME=默认文本

# 图片代理域名白名单（可选，逗号分隔）
IMAGE_PROXY_ALLOW_HOSTS=
EOF
```

### 3.2 写 `relay/api-target.conf`

模式①：生图与文本用不同服务商

```nginx
set $relay_image_pass "https://cf.api.fan/v1/";
set $relay_image_auth "Bearer sk-真实生图KEY";

set $relay_text_pass "https://api.deepseek.com/v1/";
set $relay_text_auth "Bearer sk-真实文本KEY";
```

模式②：一个 KEY 既能生图又能文本 —— 文本两行留空即可

```nginx
set $relay_image_pass "https://同一个服务商/v1/";
set $relay_image_auth "Bearer sk-真实KEY";
set $relay_text_pass "";
set $relay_text_auth "";
```

```bash
chmod 600 relay/api-target.conf
chmod 700 relay
```

> 末尾的 `/` 必须保留，Nginx 用它替换 `/api-proxy/` 前缀。
> 文本段留空时，文本请求自动回落到图像上游，不需要额外配置。

### 3.3 写 `docker-compose.yml`

```yaml
services:
  gpt-image-playground:
    image: ghcr.io/tjsky/gpt_image_playground:latest
    container_name: gpt-image-playground
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"        # 只监听本机，由外层 Nginx/CF 反代
    env_file: .env
    environment:
      ENABLE_API_PROXY: "true"
      LOCK_API_PROXY: "false"      # 允许访客用自己的 KEY 直连，所以别锁
    volumes:
      - ./relay/api-target.conf:/etc/nginx/relay/api-target.conf:ro
      - ./relay/image-allow.conf:/etc/nginx/relay/image-allow.conf:ro
```

> `ports` 写成 `127.0.0.1:8080:80` 而不是 `8080:80`：避免绕过 Cloudflare Access 直连 IP 白嫖额度。

### 3.4 启动

```bash
cd /opt/gpt-image-playground
docker compose pull
docker compose up -d

docker compose ps                      # 应为 Up
docker compose logs --tail=30          # 找 "站点 API 代理已配置：图像上游 ... 文本上游 ..."
docker compose exec gpt-image-playground nginx -t   # 应为 successful
```

日志里出现下面任一行即表示代理就绪：

```
站点 API 代理已配置：图像上游 https://cf.api.fan/，文本上游 https://api.deepseek.com/（真实 KEY 仅存在于本文件，不会进入前端产物）
站点 API 代理已配置：上游 https://.../（单 KEY 模式，文本请求复用同一上游）
```

若看到 `错误：ENABLE_API_PROXY=true，但缺少 API_PROXY_URL / API_PROXY_KEY`，说明既没挂载文件也没给环境变量，容器会直接退出。

---

## 4. 环境变量

只列与代理/部署相关的；完整列表见 [README 环境变量](../README.md#env-vars)。

| 变量 | 必填 | 作用 |
| --- | --- | --- |
| `DEFAULT_API_URL` | 是 | 前端看到的**假**地址，与真实上游无关 |
| `DEFAULT_API_KEY` | 强烈建议 | 前端持有的**假** KEY，Nginx 用它校验请求；留空会关闭校验（等于裸奔）并告警 |
| `ENABLE_API_PROXY` | 是 | `true` 才注入 `/api-proxy/` 配置块；`false` 时整块被删除 |
| `LOCK_API_PROXY` | 建议 `false` | `true` 会锁死访客的代理开关，使其无法用自己的 KEY |
| `API_PROXY_URL` / `API_PROXY_KEY` | 二选一 | 生图上游；与挂载 `api-target.conf` 二选一 |
| `TEXT_API_URL` / `TEXT_API_KEY` | 否 | 文本上游；两个都不给 = 复用生图上游 |
| `DEFAULT_TEXT_MODEL` | 否 | 预置文本配置的模型名，设置后新访客开箱即用 Agent |
| `DEFAULT_TEXT_MODEL_NAME` | 否 | 预置文本配置的显示名，默认「默认（文本）」 |
| `DEFAULT_IMAGE_MODEL` | 否 | 默认生图模型，留空用内置 `gpt-image-2.6-sunburst` |
| `IMAGE_MODEL_NOTES` | 否 | 模型注释，`模型名=注释;模型名=注释`，模型名不区分大小写 |
| `IMAGE_PROXY_ALLOW_HOSTS` | 否 | 图片代理域名白名单，逗号分隔 |

改环境变量需要 `docker compose up -d` 重建容器；改 `relay/*.conf` 只需 `reload`（见 §5）。

---

## 5. 日常运维

### 5.1 换上游 / 换 KEY（不重启）

```bash
cd /opt/gpt-image-playground
vi relay/api-target.conf            # 改 set 行
docker compose exec gpt-image-playground nginx -t
docker compose exec gpt-image-playground nginx -s reload
```

`reload` 只换 worker，容器 `RestartCount` 保持 0，正在生成的请求不受影响。

### 5.2 多中转站切换

```bash
cd /opt/gpt-image-playground/relay
cp api-target.conf api-target.a.conf
cp api-target.conf api-target.b.conf     # 再改 b

ln -sfn api-target.a.conf api-target.conf
docker compose exec gpt-image-playground nginx -s reload
```

> ⚠️ 软链接方案要求 compose 里挂载的是**文件**（`./relay/api-target.conf`）。
> 若想挂载整个目录（`./relay:/etc/nginx/relay:ro`），`ln -sfn` 同样有效，但注意别把 `.example` 也挂进去。

### 5.3 升级镜像

```bash
cd /opt/gpt-image-playground
docker compose pull
docker compose up -d
docker compose logs --tail=20
```

配置在宿主机挂载，升级不会丢。

### 5.4 回滚

```bash
docker compose down
# .env 里把 image 改成带版本号的 tag，例如 :v0.9.0-tjsky.1
docker compose up -d
```

### 5.5 备份要备什么

只备 `docker-compose.yml`、`.env`、`relay/`。**访客的设置和图片都存在各自浏览器本地**，容器无状态，不需要备份数据卷。

---

## 6. 部署后自检（逐条跑）

```bash
BASE=http://127.0.0.1:8080
FAKE=sk-fake-change-me

# 1) 无 KEY → 401
curl -s -o /dev/null -w 'no-auth:%{http_code}\n' -X POST $BASE/api-proxy/images/generations

# 2) 假 KEY + 白名单内路径 → 200（会真的出一张图，确认后删掉这步或换小尺寸）
curl -s -X POST $BASE/api-proxy/images/generations \
  -H "Authorization: Bearer $FAKE" -H 'Content-Type: application/json' \
  -d '{"model":"gpt-image-2.5-flare","prompt":"a tiny dot","size":"1024x1024","quality":"low"}' \
  -o /tmp/out.json -w 'image:%{http_code}\n'; grep -c b64_json /tmp/out.json

# 3) 白名单外路径 → 403
curl -s -o /dev/null -w 'chat:%{http_code}\n' -X POST $BASE/api-proxy/chat/completions \
  -H "Authorization: Bearer $FAKE"

# 4) 文本分流 → 200 且返回文本模型响应（证明打到文本上游）
curl -s -X POST $BASE/api-proxy/responses \
  -H "Authorization: Bearer $FAKE" -H 'X-Api-Kind: text' -H 'Content-Type: application/json' \
  -d '{"model":"deepseek-flash","input":"只回复两个字：收到"}' -w '\n[%{http_code}]\n'

# 5) 图片代理 SSRF → 403
curl -s -o /dev/null -w 'ssrf:%{http_code}\n' -H 'X-Image-URL: https://127.0.0.1/a.png' $BASE/image-proxy/

# 6) 产物里没有真实 KEY
docker compose exec gpt-image-playground sh -c \
  'grep -rl "sk-真实KEY前缀" /usr/share/nginx/html || echo NO_REAL_KEY_IN_BUNDLE'
```

预期：`401 / 200 / 403 / 200 / 403 / NO_REAL_KEY_IN_BUNDLE`。

浏览器侧再确认三点：

1. 设置 → API 配置：URL 是假地址且置灰，提示「实际请求目标由部署端决定」，代理开关为开
2. 画廊能出图
3. Agent 能对话并出图（说明文本分流生效）

---

## 7. 访问控制（必做）

Cloudflare Access：给站点建一个 Self-hosted 应用，策略设 `Allow` + 邮箱域名或指定邮箱，其余拒绝。

Nginx Basic Auth（无 Cloudflare 时）：

```nginx
location / {
    auth_basic "restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_buffering off;              # 流式输出必须关缓冲
    proxy_read_timeout 600s;
    client_max_body_size 600m;
}
```

> 前面套了 Cloudflare 时，容器限流看到的是回源 IP，要按真实访客限流需在容器内配 `realip`（`set_real_ip_from` + `real_ip_header CF-Connecting-IP`）。

---

## 8. 排错

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 容器启动即退出，日志「缺少 API_PROXY_URL / API_PROXY_KEY」 | 开了代理但没给上游 | 挂载 `relay/api-target.conf` 或补环境变量 |
| 所有代理请求 502，日志 `no resolver defined` | 上游用了变量，缺 `resolver` | 用官方镜像（模板已内置 `resolver 127.0.0.11 8.8.8.8 1.1.1.1`）；自改模板要补这一行 |
| 所有代理请求 401 | 假 KEY 不匹配 | 前端存的假 KEY 与 `DEFAULT_API_KEY` 不一致，清站点 localStorage 或改回来 |
| `images/generations` 200 但 Agent 报错 | 文本上游未配或模型名不对 | 检查 `TEXT_API_URL` / `relay_text_*`，以及 `DEFAULT_TEXT_MODEL` |
| 改了 `relay/api-target.conf` 不生效 | 没 reload，或挂载路径不对 | `nginx -t` + `nginx -s reload`；`docker exec ... cat /etc/nginx/relay/api-target.conf` 看实际内容 |
| 异步任务（`tasks/*`）403 | 白名单未放行 | 官方模板已放行 `images/tasks/*` 与 `tasks/*`；自改过白名单要同步 |
| 换行报错 `proxy_pass directive is duplicate` | 挂了旧格式（含 `proxy_pass` 行）的配置 | 按 §3.2 用 `set $relay_*` 新格式 |

---

## 9. 安全检查清单（交付前过一遍）

- [x] `relay/` 目录 `700`，`api-target.conf` `600`
- [x] 仓库里 `git status` 看不到 `relay/api-target.conf`（已被 `.gitignore` 忽略）
- [x] 镜像产物里搜不到真实 KEY（§6 第 6 条）
- [x] 容器端口只监听 `127.0.0.1`
- [x] Cloudflare Access / Basic Auth 已生效（用无痕窗口验证会被拦）
- [x] 泄露过的旧 KEY 已在上游服务商后台删除
