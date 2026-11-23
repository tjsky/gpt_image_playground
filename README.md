<div align="center">

<img src="public/pwa-icon.svg" alt="GPT Image Playground" width="128" height="128">

# GPT Image Playground 自用修改版

[![License](https://img.shields.io/badge/license-MIT-10b981?style=flat-square)](https://github.com/tjsky/gpt_image_playground/blob/main/LICENSE)
[![React](https://img.shields.io/badge/React-19-20232A?style=flat-square&logo=react&logoColor=61DAFB)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)

**支持 GPT Image、Gemini（Nano Banana）、Grok 和 Seedream 的图片生成与编辑工具（自用修改版）**

支持官方接口、OpenAI 兼容接口、sub2api、fal.ai 与自定义 HTTP 供应商。<br>
支持文本生图、参考图编辑、画板标注、遮罩编辑与 Agent 多轮对话，图片与历史记录保存在浏览器本地。

</div>

---

## 🔧 自用修改版说明

本项目是 [CookSleep/gpt_image_playground](https://github.com/CookSleep/gpt_image_playground) 的自用修改版，版本号形如 `v0.9.5-tjsky.1`：前半段跟随所基于的上游版本，后半段是本仓库自己的修订号。核心功能与架构由原作者开发，本仓库只改造部署与代理相关部分：

- **双层脱敏 API 代理**：前端只持有「假 API 地址 + 假 KEY」，真实上游与真实 KEY 只存在于容器内；Nginx 校验假 KEY 后注入真 KEY 转发，访客在前端看不到任何中转站信息。
- **图片下载中转**：中转站返回图片 URL 时改走本站 `/image-proxy/` 下载，绕开浏览器跨域限制，并带域名白名单防 SSRF。目标 URL 由请求头 `X-Image-URL` 传递（Nginx 会原样透传查询串，带 `&` 的签名 URL 会被截断）。
- 已移除上游的赞助商展示与推广预置（`sponsor-presets.json`、公告推广素材、设置页赞助入口）。

部署方式只有一种：Docker 镜像 + `docker compose`，完整步骤见 [`deploy/DEPLOY-DOCKER.md`](deploy/DEPLOY-DOCKER.md)；代理原理与配置见 [站点 API 代理](#site-api-proxy)。

---

## ✨ 核心特性

### 🎨 图像生成与编辑

- **参考图与遮罩**：最多 16 张参考图（支持剪贴板、拖拽和图片链接），内置遮罩编辑器，自动预处理以符合官方分辨率限制；SVG 和 GIF 作为参考图时转为 PNG（GIF 取第一帧）。
- **画板标注**：在空白画布或参考图上用画笔、文字、图形和像素橡皮擦标注修改意图；画板与遮罩编辑器可缩放平移（Alt / Ctrl + 滚轮、Alt + 拖动、双指捏合）。
- **评论标注**：在画板中用评论工具点击图片添加评论，以「@图N 评论」插入提示词，发送时附上评论在图中的位置（如 `(X=52%, Y=41%)`），复用任务时可恢复。
- **GPT Image 2.6 参数**：在「更多」中设置；当前模型或模式不支持时，选项置灰并说明原因。
  - **复杂度**：`auto`、`low`、`medium`、`high`。
  - **GIF 动图**：仅画廊模式，可设置帧数（2–16，默认 9）和每帧时长（20–2000 ms，默认 200），带参考图时也可用。
  - **SVG**：仅画廊模式，只能文生图；由文本模型编写，可在「设置 → API 配置」中指定 SVG 编写模型（留空时使用 Agent 配置的文本模型）。
- **批量与迭代**：支持单次多图生成；一键将满意结果转为参考图，无缝开启下一轮修改。
- **多提示词批量提交**：在习惯配置中开启后，可一次粘贴多条提示词（以两个空行分隔），共用参考图和参数；支持排队或并发（默认上限 10），可随时查看进度或停止。
- **流式生成预览**：`Images API` 与 `Responses API` 模式均支持流式接收中间步骤图像，缓解连接超时问题。
- **透明背景**：画廊模式下选择 PNG、WebP、SVG 或 GIF 后可开启，可按配置选择 API 原生或本地后处理。接口返回「不支持透明背景」类错误时会提示切换为本地后处理；本地后处理要求模型输出纯绿或纯洋红背景，主体边缘复杂时可能残留。

### 🤖 Agent 多轮对话

- **多轮对话与上下文记忆**：基于 Responses API，Agent 理解上下文并按需调用图像工具；可用 `@` 引用参考图或之前生成的图片，也会自动识别上下文中的图片。
- **风格一致性**：历史生成的图片会连同当时的提示词一起回灌给模型，后续轮次可自动引用；需要强约束时在输入框手打 `@第N轮图M` 即可把那张图挂进本轮参考。
- **并发批量生成**：`generate_image_batch` 在一轮中并发生成多张关联图像，`continue_generation` 自动追加新一轮以处理依赖关系。
- **分支与重新生成**：编辑重发或重新生成某轮消息会产生可切换的分支，图片引用只在当前分支内解析。
- **画廊同步与隔离删除**：Agent 生成的图片同步到画廊；删除对话默认保留画廊记录，删除画廊任务时自动清理对话中的图片引用。
- **可选 Web 搜索**：可开启 `web_search` 工具，Agent 会在需要时搜索网络信息并附带引用链接。

### ⚙️ 参数与历史管理

- **智能尺寸控制**：提供 1K/2K/4K 预设，自定义宽高时自动规整到模型安全范围（16 的倍数、总像素校验等）。
- **实际参数对比**：提取 API 响应中实际生效的尺寸、比例、分辨率、质量、耗时和模型改写后的提示词，与请求参数高亮对比。
- **瀑布流与画廊**：历史任务自动保存，支持按状态过滤、全屏大图预览与快捷下载。
- **多收藏夹管理**：同一任务可归入多个收藏夹；支持拖拽排序、重命名、设为默认和按收藏夹打包下载 ZIP。
- **失败任务重试**：重试方式可选新建任务或覆盖原任务；覆盖时保留创建时间和收藏，耗时重新计算。
- **快捷批量操作**：桌面端支持拖拽框选、Ctrl/⌘ 连选，移动端支持侧滑多选，便于批量收藏与清理。
- **性能与隐私**：记录和图片只保存在浏览器本地（IndexedDB），SHA-256 去重压缩，不经过第三方服务器；可打包导出 ZIP 备份。

### 🔌 多配置与供应商

- **多配置管理**：保存多个 API 配置（供应商、API Key、模型等）并快速切换；可一键复制当前配置到列表底部，配置和供应商列表均可拖拽排序。
- **多模型切换**：模型 ID 可用逗号分隔填写多个（如 `gpt-image-2.6-sunburst,gpt-image-2.6-flare`），在首页下拉切换（支持搜索，也可跨配置直接切换），按配置分别记住。
- **多供应商接入**：内置 OpenAI 兼容接口（`Images API` / `Responses API`）、Google、xAI、字节跳动（Seedream）、sub2api（异步）、fal.ai（队列），并可导入自定义 HTTP 供应商（同步/异步任务）。自定义供应商的字段定义与 LLM 提示词见 [`docs/custom-provider-llm-prompt.md`](docs/custom-provider-llm-prompt.md)。
- **Agent 独立 API 配置**：Agent 可使用原生（Responses API）或混合（Responses API + Images API）的独立配置，适配不支持 `image_generation` 工具的供应商或模型。
- **API 代理**：OpenAI 兼容接口可走同源 `/api-proxy/`，由容器内的 Nginx 转发；也可为每个配置单独配置外网代理。
- **Codex CLI 兼容模式**：上游为 Codex CLI 时，按其实际支持的参数发送请求，并把多图生成拆成并发单图。
- **提示词防改写**：Responses API 始终在请求前加入防改写指令；开启 Codex CLI 模式后，Images API 也会加入。
- **智能诊断提示**：检测到接口异常改写或缺少常规参数时，提示开启相应的兼容模式。
- **外观与习惯配置**：颜色模式、界面字体与代码字体；提交后清空输入、重启后保留输入、重试方式、系统通知等。

---

## 🚀 部署

本仓库只发布 Docker 镜像，用 `docker compose` 部署到自己的服务器，配合外层 Nginx / Cloudflare Access 做访问控制。**完整步骤见 [`deploy/DEPLOY-DOCKER.md`](deploy/DEPLOY-DOCKER.md)**，这里只给最小示例：

```yaml
services:
  gpt-image-playground:
    image: ghcr.io/tjsky/gpt_image_playground:latest
    restart: unless-stopped
    # 只监听本机，由外层 Nginx / Cloudflare 反代，避免直接暴露端口
    ports: ["127.0.0.1:8080:80"]
    environment:
      DEFAULT_API_URL: https://api.example.com/v1   # 前端可见的假地址
      DEFAULT_API_KEY: sk-fake-please-change        # 前端可见的假 KEY
      ENABLE_API_PROXY: "true"
      LOCK_API_PROXY: "false"
    volumes:
      - ./relay:/etc/nginx/relay:ro
```

真实上游与真实 KEY 写在挂载的 `relay/api-target.conf` 里（不进镜像、不进 git），改完 `docker compose exec gpt-image-playground nginx -s reload` 即可生效，不用重建镜像。

发版流程：推送 `v*` tag 触发唯一一条工作流构建并推送镜像到 GHCR，不产生任何公开网页。

---

<a id="site-api-proxy"></a>
## 🛡️ 站点 API 代理（双层脱敏）

本版本在 Nginx 层加了一层「假 KEY 校验 + 真 KEY 注入」：站点对访客开箱即用，而访客在前端既看不到中转站信息，也拿不到可用的真实 KEY。图片与文本两条通道都支持，且可以分别指向不同服务商。

```
浏览器 ──「假地址 + 假 KEY」──▶ 本站 Nginx ──「真实上游 + 真实 KEY」──▶ 服务商
                                │
                                ├─ /api-proxy/images/* 与不带标记的 responses → 图像上游
                                ├─ /api-proxy/responses（X-Api-Kind: text）     → 文本上游
                                └─ /image-proxy/       校验 X-Image-URL 头后中转图片，绕开跨域
```

- 访客使用默认配置时，前端把请求发到同源 `/api-proxy/...`；Nginx 校验 `Authorization` 是否等于假 KEY，再改写成真实 KEY 转发到真实上游。
- 分流靠请求头 `X-Api-Kind`：Agent 的文本请求带 `text`，生图请求不带（默认图像）。这个头由前端自动加，访客无需感知。
- 访客新建配置填自己的 API 地址与 KEY 时，请求不经本站代理，直连自己的服务商（因此 `LOCK_API_PROXY` 应保持 `false`）。
- 真实上游与真实 KEY 只存在于容器环境变量或挂载的 `relay/api-target.conf`，**不会进入 JS 产物**。

### 两种 KEY 配置

| 模式 | 适用 | 配置方式 |
| --- | --- | --- |
| ① 双 KEY | 生图与文本用不同服务商（或同一家的不同分组） | `API_PROXY_URL`+`API_PROXY_KEY` 填生图；`TEXT_API_URL`+`TEXT_API_KEY` 填文本 |
| ② 单 KEY 全能 | 一个 KEY 既能生图又能文本 | 只填 `API_PROXY_URL`+`API_PROXY_KEY`，文本段留空即自动回落到图像上游 |

> 混合 Agent 模式（文本模型调用工具生图）支持双 KEY。**原生 Agent 模式**（由上游模型自带 `image_generation` 工具）要求同一个 KEY 同时返回文本与图像，因此只能用模式 ②。

### 访客开箱即用（预置文本配置）

设置 `DEFAULT_TEXT_MODEL`（如 `deepseek-flash`）后，首次访问的浏览器会自动带上两份配置：

- `默认`：生图配置（模型为 `DEFAULT_IMAGE_MODEL`）
- `默认文本`：`apiMode=responses`，模型为 `DEFAULT_TEXT_MODEL`，同样走本站代理、同一个假 KEY

并自动把 Agent 切到「混合模式」，访客打开 Agent 就能直接对话生图。可选 `DEFAULT_TEXT_MODEL_NAME` 自定义这份配置的显示名。

> 只有「首次访问 / 空本地存储」的用户会得到预置；已有本地设置的老用户不受影响。

### 默认生图模型与模型注释

两个部署端变量（只影响前端展示，不含任何凭据）：

```yaml
DEFAULT_IMAGE_MODEL: gpt-image-2.6-flare;gpt-image-2.6-sunburst
IMAGE_MODEL_NOTES: gpt-image-2.6-sunburst=顶级模型;gpt-image-2.6-flare=正常模型，适合日常使用
```

- `DEFAULT_IMAGE_MODEL` 决定**新建配置**的默认模型列表：用分号分隔多个模型（也接受逗号、换行），**默认选中第一个**，其余可在首页下拉切换。已有配置不会被改动；留空时用内置的 `gpt-image-2.6-sunburst`。
- `IMAGE_MODEL_NOTES` 用分号分隔条目、等号分隔模型与注释，注释里可以带逗号。模型名**不区分大小写**（`gpt-image-2.6-Flare` 与 `gpt-image-2.6-flare` 共用一条注释）。
- 注释**只出现在展开的模型下拉里**（如 `gpt-image-2.6-flare （正常模型，适合日常使用）`）；选中后输入栏只显示纯模型 ID，避免底部输入框被撑长。
- 下拉选中的值始终是纯模型 ID，注释不会发给接口；一个配置里的每个模型各自匹配注释。

### 管理中转站（挂载配置文件，reload 生效）

1. 复制 [`deploy/relay/api-target.conf.example`](deploy/relay/api-target.conf.example) 为 `relay/api-target.conf`，按注释填 `$relay_image_*` / `$relay_text_*` 四行（`chmod 600`，不要提交到 git）。
2. 复制 [`deploy/relay/image-allow.conf.example`](deploy/relay/image-allow.conf.example) 为 `relay/image-allow.conf`，填中转站图片 CDN 域名白名单（不填则只依赖内置的 https 与内网地址拦截）。
3. 改完执行：

```bash
docker compose exec gpt-image-playground nginx -s reload
```

多中转站：每个站一份 `api-target.<名字>.conf`，用软链接切换后 reload：

```bash
ln -sfn api-target.a.conf relay/api-target.conf
docker compose exec gpt-image-playground nginx -s reload
```

不挂载文件时，也可用 `API_PROXY_URL` / `API_PROXY_KEY` / `TEXT_API_URL` / `TEXT_API_KEY` / `IMAGE_PROXY_ALLOW_HOSTS` 环境变量，容器启动时自动生成同样的片段（改这些变量需要重启容器）。

### 安全提醒

- 代理对访客开箱即用，等于把额度开放给所有能访问站点的人：外层务必加 Cloudflare Access 或 Nginx Basic Auth，并留意上游用量。
- 已内置：路径白名单（仅 `images/generations`、`images/edits`、`images/tasks/*`、`responses`、`tasks/*`）、每 IP 限流、图片代理仅允许 https 且拦截环回/内网地址。
- `X-Api-Kind` 只是分流标记，访客可以自己指定——它只会决定用哪套真实 KEY，不会拿到 KEY 本身。
- 若前面还有 Cloudflare，限流看到的是回源 IP，需另配 realip 才能按真实访客限流。

### 自检命令

```bash
# 假 KEY 不匹配 → 401
curl -o /dev/null -w '%{http_code}\n' -X POST http://localhost:8080/api-proxy/images/generations
# 白名单外的路径 → 403
curl -o /dev/null -w '%{http_code}\n' -X POST -H 'Authorization: Bearer sk-fake-please-change' \
  http://localhost:8080/api-proxy/chat/completions
# 文本分流：带 X-Api-Kind: text 应打到文本上游（返回 JSON 即通）
curl -s -X POST http://localhost:8080/api-proxy/responses \
  -H 'Authorization: Bearer sk-fake-please-change' -H 'X-Api-Kind: text' \
  -H 'Content-Type: application/json' -d '{"model":"deepseek-flash","input":"只回复两个字：收到"}'
# 图片代理 SSRF → 403（目标 URL 走请求头；?url= 仍兼容，但不支持带 & 的签名 URL）
curl -o /dev/null -w '%{http_code}\n' -H 'X-Image-URL: http://127.0.0.1/a.png' http://localhost:8080/image-proxy/
curl -o /dev/null -w '%{http_code}\n' -H 'X-Image-URL: https://169.254.169.254/latest/meta-data/' http://localhost:8080/image-proxy/
```

---

<a id="env-vars"></a>
## ⚙️ 环境变量

Docker 部署时用去掉 `VITE_` 前缀的同名变量，容器启动时读取；改环境变量需重启容器（只有 `relay` 挂载文件支持热 reload）。

### 站点代理（只在容器内，不会进入前端产物）

| 变量 | 说明 |
|------|------|
| `DEFAULT_API_URL` | 前端可见的假地址，随便填（如 `https://api.example.com/v1`） |
| `DEFAULT_API_KEY` | 前端可见的假 KEY，仅用于 Nginx 校验，泄露无价值；留空则自动关闭校验 |
| `API_PROXY_URL` / `API_PROXY_KEY` | 真实生图上游地址与 KEY |
| `TEXT_API_URL` / `TEXT_API_KEY` | 真实文本上游地址与 KEY；留空则文本请求复用生图上游 |
| `IMAGE_PROXY_ALLOW_HOSTS` | 图片代理域名白名单，逗号分隔，如 `cdn.example.com,files.example.com` |
| `ENABLE_API_PROXY` | `true` 开启 `/api-proxy/`，默认 `false` |
| `LOCK_API_PROXY` | `true` 强制开启代理、用户无法关闭，默认 `false` |
| `HOST` / `PORT` | Nginx 监听地址与端口，默认 `0.0.0.0:80` |

### 前端预置

| 变量 | 说明 |
|------|------|
| `DEFAULT_IMAGE_MODEL` | 新建配置的默认生图模型，可用 `;` 分隔多个（默认选第一个），留空用内置 `gpt-image-2.6-sunburst` |
| `IMAGE_MODEL_NOTES` | 模型注释，格式 `模型名=注释;模型名=注释`，模型名不区分大小写 |
| `DEFAULT_TEXT_MODEL` | 预置文本配置的模型名（如 `deepseek-flash`），设置后新访客开箱即用 Agent |
| `DEFAULT_TEXT_MODEL_NAME` | 预置文本配置的显示名，默认「默认（文本）」 |
| `DEFAULT_UI_FONT` / `DEFAULT_MONO_FONT` | 默认界面字体 / 代码字体：`builtin`（内置，默认）、`system`（系统字体）或本机字体名 |
| `BUILTIN_FONT_SOURCE` | 内置字体来源：`cdn`（默认，公共 CDN）或 `local`（镜像内的 [`fonts/`](fonts) 目录） |

---

<a id="announcements"></a>
## 📢 公告卡片

[`public/announcements.json`](public/announcements.json) 定义启动时显示的公告卡片，随应用一起打包。本仓库默认置为 `[]`（不显示任何公告），需要时往里追加对象即可：`id`（唯一标识，换 id 才会再次提示）、`title`、`content`（Markdown）、可选的 `note`、`action`（按钮）、`media`（`public/announcements/` 下的 html 或图片）与 `when`（按平台、语言、版本、图片数等条件显示）。媒体文件放在 `public/announcements/`。

---

## 🔤 字体许可

本项目内置以下两款字体，由 `BUILTIN_FONT_SOURCE` 决定从公共 CDN 加载还是使用 [`fonts/`](fonts) 目录中的字体文件。完整许可文本位于 [`third-party-licenses/`](third-party-licenses)，也可在应用的「设置 → 关于 → 第三方许可」中查看。

| 字体 | 版权方 | 许可 | 项目地址 | 许可文件 |
|------|------|------|------|------|
| HarmonyOS Sans SC | Huawei Device Co., Ltd. | HarmonyOS Sans Fonts License Agreement | [HarmonyOS 设计资源](https://developer.huawei.com/consumer/cn/design/resource/)，[许可证（License）](https://github.com/openharmony/resources/blob/master/LICENSE_Fonts) | [`third-party-licenses/HarmonyOS-Sans-LICENSE.txt`](third-party-licenses/HarmonyOS-Sans-LICENSE.txt) |
| Maple Mono NF CN | The Maple Mono Project Authors | SIL Open Font License 1.1 | [subframe7536/maple-font](https://github.com/subframe7536/maple-font) | [`third-party-licenses/MapleMono-LICENSE.txt`](third-party-licenses/MapleMono-LICENSE.txt) |

- HarmonyOS Sans SC 为官方未经修改的 TTF 文件（Regular、Medium、Bold）。
- Maple Mono NF CN 取自官方 v7.9 Release 的 Regular 字重，按 OFL 转换为 woff2 格式，未改动字形和名称。

## 📄 许可证 & 致谢

本项目基于 [MIT License](LICENSE) 开源，核心功能来自 [CookSleep/gpt_image_playground](https://github.com/CookSleep/gpt_image_playground)。
