<div align="center">

<img src="public/pwa-icon.svg" alt="GPT Image Playground" width="128" height="128">

# GPT Image Playground 自用修改版

[![GitHub Repo stars](https://img.shields.io/github/stars/tjsky/gpt_image_playground?style=flat-square&color=eab308)](https://github.com/tjsky/gpt_image_playground/stargazers)
[![License](https://img.shields.io/badge/license-MIT-10b981?style=flat-square)](https://github.com/tjsky/gpt_image_playground/blob/main/LICENSE)
[![React](https://img.shields.io/badge/React-19-20232A?style=flat-square&logo=react&logoColor=61DAFB)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)

**支持 GPT Image、Gemini（Nano Banana）和 Grok 的图片生成与编辑工具（自用修改版）**

提供 Web UI 和 Windows 客户端，支持官方接口、OpenAI 兼容接口、sub2api、fal.ai 与自定义 HTTP 供应商。<br>
支持文本生图、参考图编辑、画板标注、遮罩编辑与 Agent 多轮对话，图片和历史记录保存在本地。

</div>

---

## 🔧 自用修改版说明

本项目是 [CookSleep/gpt_image_playground](https://github.com/CookSleep/gpt_image_playground) 的自用修改版（版本号形如 `v0.9.0-tjsky.1`）。核心功能与架构由原作者开发，本仓库只改造部署与代理相关部分：

- **双层脱敏 API 代理**：前端只持有「假 API 地址 + 假 KEY」，真实上游与真实 KEY 只存在于容器内；Nginx 校验假 KEY 后注入真 KEY 转发，访客在前端看不到任何中转站信息。
- **图片下载中转**：中转站返回图片 URL 时改走本站 `/image-proxy/` 下载，绕开浏览器跨域限制，并带域名白名单防 SSRF。目标 URL 由请求头 `X-Image-URL` 传递（查询串会被 Nginx 原样透传，带 `&` 的签名 URL 会被截断）。
- 已移除上游的赞助商展示与推广预置（`sponsor-presets.json`、公告推广素材、设置页赞助入口）。

部署方式只有一种：Docker 镜像 + `docker compose`，见 [`deploy/DEPLOY-DOCKER.md`](deploy/DEPLOY-DOCKER.md)。配置方法见 [站点 API 代理](#site-api-proxy)。

---

## 📸 界面预览

<details>
<summary><b>点击展开截图展示</b></summary>
<br>

<div align="center">
  <b>桌面端主界面</b><br>
  <img src="docs/images/example_pc_1.jpg" alt="桌面端主界面" />
</div>

<br>

<div align="center">
  <b>任务详情与实际参数</b><br>
  <img src="docs/images/example_pc_2.jpg" alt="任务详情与实际参数" />
</div>

<br>

<div align="center">
  <b>桌面端批量选择</b><br>
  <img src="docs/images/example_pc_3.jpg" alt="桌面端批量选择" />
</div>

<br>

<div align="center">
  <b>桌面端 Agent 模式</b><br>
  <img src="docs/images/example_pc_4.jpg" alt="桌面端 Agent 模式" />
</div>

<br>

<div align="center">
  <b>移动端主界面</b><br>
  <img src="docs/images/example_mb_1.jpg" alt="移动端主界面" width="420" />
</div>

<br>

<div align="center">
  <b>移动端侧滑多选</b><br>
  <img src="docs/images/example_mb_2.jpg" alt="移动端侧滑多选" width="420" />
</div>

</details>

---

## ✨ 核心特性

### 🎨 强大的图像生成与编辑
- **参考图与遮罩**：最多 16 张参考图（支持剪贴板、拖拽和图片链接），内置遮罩编辑器，自动预处理以符合官方分辨率限制；SVG 和 GIF 作为参考图时转为 PNG（GIF 取第一帧）。
- **画板标注**：在空白画布或参考图上用画笔、文字、图形和像素橡皮擦标注修改意图；画板与遮罩编辑器可缩放平移（Alt / Ctrl + 滚轮、Alt + 拖动、双指捏合）。

  > - **参考图上的标注**：单独保存为透明图层，原图保持不变。`Images API` 使用 GPT Image 2.5 及以上模型、或使用 fal.ai 的 GPT Image 2.6 时，第一张参考图的标注以 markup 方式发送；其他情况合成到图上再发送。

- **评论标注**：在画板中用评论工具点击图片添加评论，以“@图N 评论”插入提示词，发送时附上评论在图中的位置（如 `(X=52%, Y=41%)`），复用任务时可恢复。
- **GPT Image 2.6 参数**：在「更多」中设置；当前模型或模式不支持时，选项置灰并说明原因。

  > - **复杂度**：`auto`、`low`、`medium`、`high`。
  > - **GIF 动图**：仅画廊模式，可设置帧数（2–16，默认 9）和每帧时长（20–2000 ms，默认 200），带参考图时也可用。
  > - **SVG**：仅画廊模式，只能文生图；由文本模型编写，可在 **「设置 → API 配置」** 中指定 SVG 编写模型。
  > - **供应商支持**：OpenAI 兼容接口（含 Codex CLI 模式）全部支持；fal.ai 支持复杂度和 GIF，暂不支持 SVG；自定义供应商需在模板中映射对应的 `$params` 变量。

- **批量与迭代**：支持单次多图生成；一键将满意结果转为参考图，无缝开启下一轮修改。
- **多提示词批量提交**：在习惯配置中开启后，可一次粘贴多条提示词（以两个空行分隔），共用参考图和参数；支持排队或并发（默认上限 10），可随时查看进度或停止。
- **流式生成预览**：`Images API` 与 `Responses API` 模式均支持流式接收中间步骤图像，缓解连接超时问题。
- **透明背景**：画廊模式下选择 PNG、WebP、SVG 或 GIF 后可开启，可在 API 配置页为每个配置分别选择 API 原生或本地后处理。

  > - **API 原生**：直接请求模型返回透明通道，需接口和模型支持。接口返回“不支持透明背景”类错误时，应用会提示切换为本地后处理。
  > - **本地后处理**：要求模型使用纯绿或纯洋红背景，结果返回后在浏览器中去除背景色，按所选格式保存。适合图标、贴纸、单主体素材；主体有复杂发丝、半透明材质、强反光或颜色接近背景色时，边缘可能残留或误抠。
  > - **SVG 和 GIF**：只使用 API 原生方式；自定义供应商的生成和编辑请求未映射 `$params.background` 时不提供透明背景。

### 🤖 Agent 多轮对话模式
- **多轮对话与上下文记忆**：基于 Responses API，Agent 理解上下文并按需调用图像工具；可用 `@` 引用参考图或之前生成的图片，也会自动识别上下文中的图片。
- **并发批量生成**：`generate_image_batch` 在一轮中并发生成多张关联图像，`continue_generation` 自动追加新一轮以处理依赖关系。
- **分支与重新生成**：编辑重发或重新生成某轮消息会产生可切换的分支，图片引用只在当前分支内解析。
- **画廊同步与隔离删除**：Agent 生成的图片同步到画廊；删除对话默认保留画廊记录，删除画廊任务时自动清理对话中的图片引用。
- **可选 Web 搜索**：可开启 `web_search` 工具，Agent 会在需要时搜索网络信息并附带引用链接。

### ⚙️ 精细化参数追踪
- **智能尺寸控制**：提供 1K/2K/4K 预设，自定义宽高时自动规整到模型安全范围（16 的倍数、总像素校验等）。
- **实际参数对比**：提取 API 响应中实际生效的尺寸、质量、耗时和**模型改写后的提示词**，与请求参数高亮对比。

### 📁 高效历史管理 (纯本地)
- **瀑布流与画廊**：历史任务自动保存，支持按状态过滤、全屏大图预览与快捷下载。
- **多收藏夹管理**：同一任务可归入多个收藏夹；概览页显示封面和任务数，进入后可叠加搜索与状态筛选；支持拖拽排序、重命名、设为默认和按收藏夹打包下载 ZIP；在收藏夹页新建的任务自动归入当前收藏夹。
- **失败任务重试**：重试方式可选新建任务或覆盖原任务（不限失败任务）；覆盖时保留创建时间和收藏，耗时重新计算。
- **快捷批量操作**：桌面端支持拖拽框选、Ctrl/⌘ 连选，移动端支持侧滑多选，便于批量收藏与清理。
- **图片查看与下载**：大图预览支持左右滑动切换，移动端可长按弹出操作菜单，支持快捷下载与批量下载。
- **性能与隐私**：记录和图片只保存在本地（网页版为 IndexedDB，客户端为本机数据目录），SHA-256 去重压缩，不经过第三方服务器；可打包导出 ZIP 备份。

### 🔌 多配置与供应商增强
- **多配置管理**：保存多个 API 配置（供应商、API Key、模型等）并快速切换；可一键复制当前配置到列表底部，配置和供应商列表均可拖拽排序。
- **多模型切换**：模型 ID 可用逗号分隔填写多个（如 `gpt-image-2.6-sunburst, gpt-image-2`），在首页切换，按配置分别记住；预置配置、URL 传参与导入导出均支持此写法。
- **多供应商接入**：内置 OpenAI 兼容接口（`Images API` / `Responses API`）、Google、xAI、sub2api（异步）、fal.ai（队列），并可通过 JSON 导入自定义 HTTP 供应商（同步/异步任务）。
- **Gemini / Grok 图像生成**：支持官方接口和 OpenAI Images 兼容接口。
- **Google Search / Image Search**：部分 Gemini 模型支持网页和图片搜索，详情展示来源与搜索建议。
- **Agent 模式独立 API 配置**：Agent 可使用原生（Responses API）或混合（Responses API + Images API）的独立配置，适配不支持 `image_generation` 工具的供应商或模型。
- **API 代理**：OpenAI 兼容接口与 fal.ai 均可配置自定义代理；OpenAI 兼容接口还可走同源 `/api-proxy/`，由 Docker 或本地开发服务器转发，绕开浏览器 CORS 限制。
- **Codex CLI 兼容模式**：上游为 Codex CLI 时，按其实际支持的参数发送请求，并把多图生成拆成并发单图。
- **提示词防改写**：Responses API 始终在请求前加入防改写指令；开启 Codex CLI 模式后，Images API 也会加入。
- **智能诊断提示**：检测到接口异常改写或缺少常规参数时，提示开启相应的兼容模式。
- **外观配置**：颜色模式（跟随系统、浅色、深色）、界面字体与代码字体。
- **习惯配置**：提交后清空输入、重启后保留输入、临时复用历史任务的 API 配置、重试方式、关闭提示词防改写、附加图像生成提示词、系统通知、自动检查更新、隐私模式快捷键等。
- **版本更新**：启动时检查新版本并展示更新说明；客户端可直接下载并安装更新。
- **CLI 与 Skill**：Claude Code、Codex 等本机 AI 工具可通过客户端的 CLI 生图、读取历史和修改设置，见 [Windows 桌面客户端](#desktop-client)。

---

## 🚀 部署与使用

本仓库只发布 **Docker 镜像**，用 `docker compose` 部署到自己的服务器，配合外层 Nginx / Cloudflare Access 做访问控制。完整步骤见 [`deploy/DEPLOY-DOCKER.md`](deploy/DEPLOY-DOCKER.md)。

部署时可以通过环境变量 `VITE_DEFAULT_API_URL` 提供**预置配置**：部署端预先加入用户配置列表的 API 配置，格式与用户自建的配置相同，用户打开页面通常只需补充 API Key。

完整写法见 [预置配置](#preset-config)，其余变量见 [环境变量](#env-vars)。

仓库中只剩一条发布工作流：推送 `v*` tag 时构建并推送 Docker 镜像到 GHCR。桌面客户端的构建入口保留为手动触发，不参与发版。

<a id="desktop-client"></a>
<details>
<summary><strong>🖥️ 方式一：Windows 桌面客户端</strong></summary>

客户端的数据保存在本机，不受浏览器存储配额和跨域限制影响，可直连任意中转 API。

**安装**

- 在 [Releases](https://github.com/CookSleep/gpt_image_playground/releases/latest) 中下载以 `_x64-setup.exe` 结尾的安装包。
- 安装包没有代码签名，遇到 SmartScreen 提示时点击 **「更多信息 → 仍要运行」**。
- 安装到普通文件夹（如 `D:\Apps\GPT Image Playground`）。装到 `C:\Program Files` 等需要管理员权限写入的位置会导致无法保存数据。
- 数据默认保存在 `<安装目录>\data` 中，可在 **「设置 → 数据管理」** 中更改。

**CLI 与 Skill**

Claude Code、Codex 等本机 AI 工具可以通过 CLI `gpt-image-playground` 调用客户端：生成和编辑图片、读取历史记录、查看和修改全部设置（API Key 只能写入）。

- 安装时勾选“添加到 PATH”即可直接运行；使用时客户端需要保持打开，用法见 `gpt-image-playground --help`。
- 在 **「设置 → Skill」** 中安装随附的 Skill，AI 工具就知道何时、如何调用它；客户端启动时会自动把已安装的 Skill 更新到当前版本。

**自行构建**

需要 Rust 和 Tauri 的 Windows 构建环境，见 [Tauri 前置条件](https://v2.tauri.app/start/prerequisites/)。

```bash
npm install
npm run tauri:dev
npm run tauri:build
```

- 客户端构建读取 [`src-tauri/.env`](src-tauri/.env)，不读取根目录的 `.env`；可在 `src-tauri/.env.local` 中覆盖。
- 客户端专用变量 `VITE_WEB_APP_URL`：复制导入链接时使用的网页版地址，未设置时改用 `gpt-image-playground://` 链接。
- `tauri:build` 需设置 `TAURI_SIGNING_PRIVATE_KEY`（私钥内容或路径）和 `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`，用于给更新包签名。
- 自行分发时，用 `npx tauri signer generate` 生成自己的密钥，并替换 `src-tauri/tauri.conf.json` 中的 `plugins.updater.pubkey` 和更新地址。
- 本仓库**不构建**桌面客户端，上面的安装包来自上游发布版；`src-tauri/` 仅作保留。

</details>

<a id="docker-deployment"></a>
<details>
<summary><strong>🐳 方式二：Docker 部署（唯一支持的方式）</strong></summary>

使用官方镜像在服务器或本地容器环境中运行。

**Docker CLI**

```bash
docker run -d -p 8080:80 \
  -e DEFAULT_API_URL=https://api.openai.com/v1 \
  ghcr.io/cooksleep/gpt_image_playground:latest
```

使用 host 网络时加 `--network host`，修改监听端口用 `-e PORT=28080`。

**Docker Compose**

```yaml
services:
  gpt-image-playground:
    image: ghcr.io/cooksleep/gpt_image_playground:latest
    environment:
      - DEFAULT_API_URL=https://api.openai.com/v1
    ports:
      - "8080:80"
    restart: unless-stopped
```

**挂载配置文件**

`DEFAULT_API_URL` 指向容器内路径时，宿主机上的 JSON 配置文件需通过 volume 挂载：

```bash
docker run -d -p 8080:80 \
  -v ./gpt-image-config.json:/config/gpt-image-config.json:ro \
  -e DEFAULT_API_URL=/config/gpt-image-config.json \
  ghcr.io/cooksleep/gpt_image_playground:latest
```

**Docker 专属变量**

| 变量 | 说明 |
|------|------|
| `ENABLE_API_PROXY=true` | 开启 Nginx 同源代理，请求发往 `/api-proxy/{路径}` 再转发到 `API_PROXY_URL` |
| `API_PROXY_URL` | 代理转发的完整 API 基础地址（不自动补 `/v1`） |
| `LOCK_API_PROXY=true` | 强制开启代理，用户无法关闭；需同时设置 `ENABLE_API_PROXY=true` |
| `HOST` / `PORT` | Nginx 监听地址和端口，默认 `0.0.0.0:80` |

> 开启 API 代理后，任何人都能将你的服务器作为代理来请求目标 API。建议仅在有访问控制（如 IP 白名单）或本地网络中开启。

> 旧版 `API_URL` 已拆分为 `DEFAULT_API_URL` 和 `API_PROXY_URL`，容器启动时自动兼容，无需立即修改。

**隐藏真实 API 地址**

同时开启 `ENABLE_API_PROXY` 和 `LOCK_API_PROXY`，真实地址只写在 `API_PROXY_URL` 中：

- OpenAI 兼容接口：`DEFAULT_API_URL` 留空或填占位地址（如 `https://proxy`）。
- 自定义供应商：预置 JSON 中的 `baseUrl` 留空并设置 `apiProxy: true`（仅支持同步配置）。

```bash
docker run -d -p 8080:80 \
  -e DEFAULT_API_URL= \
  -e API_PROXY_URL=https://real-api.example.com/v1 \
  -e ENABLE_API_PROXY=true \
  -e LOCK_API_PROXY=true \
  ghcr.io/cooksleep/gpt_image_playground:latest
```

**更新方式**

使用 `latest` 标签时，重新拉取镜像并重启即可（如 `docker compose pull && docker compose up -d`）。需要固定版本时使用版本号标签（如 `0.2.x`）。

</details>

<details>
<summary><strong>💻 方式三：本地开发与静态构建</strong></summary>

**1. 环境变量（可选）**

在项目根目录新建 `.env.local`：

```dotenv
VITE_DEFAULT_API_URL=https://api.openai.com/v1
```

**2. 安装依赖并启动**

```bash
npm install
npm run dev
```

**3. 本地开发跨域代理（可选）**

本地开发遇到浏览器 CORS 限制时，可开启开发服务器代理：

```bash
cp dev-proxy.config.example.json dev-proxy.config.json
```

- 将 `dev-proxy.config.json` 中的 `target` 设为完整的 API 基础地址。代理不会自动补 `/v1`，OpenAI 兼容接口通常要写到版本前缀，如 `https://api.example.com/v1`。
- 重启开发服务器，在 **「设置 → API 配置」** 中开启“API 代理”，请求会按 `http://localhost:5173/api-proxy/... -> target/...` 转发。
- 仅在 `npm run dev` 时生效，不影响构建产物。

**4. 本地故障模拟 API（可选）**

复现图片 URL 跨域、接口返回结构异常、原始响应查看等问题时，可启动内置模拟服务：

```powershell
npm run mock:api
```

用法见 [本地故障模拟 API](docs/mock-image-api.md)。

**5. 构建静态产物**

```bash
npm run build
```

产物位于 `dist/`，可部署到任意静态文件服务器（如 Nginx、Netlify）。

</details>

---

<a id="site-api-proxy"></a>
## 🛡️ 站点 API 代理（双层脱敏）

本版本在 Nginx 层加了一层「假 KEY 校验 + 真 KEY 注入」：站点对访客开箱即用，而访客在前端既看不到中转站信息，也拿不到可用的真实 KEY。图片与文本两条通道都支持，且可以分别指向不同服务商。

> 完整的服务器部署、挂载、升级与排错步骤见 [`deploy/DEPLOY-DOCKER.md`](deploy/DEPLOY-DOCKER.md)。

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

- `默认`：生图配置（模型为内置默认图像模型）
- `默认文本`：`apiMode=responses`，模型为 `DEFAULT_TEXT_MODEL`，同样走本站代理、同一个假 KEY

并自动把 Agent 切到「混合模式」，访客打开 Agent 就能直接对话生图。可选 `DEFAULT_TEXT_MODEL_NAME` 自定义这份配置的显示名。

> 只有「首次访问 / 空本地存储」的用户会得到预置；已有本地设置的老用户不受影响，需要自己在设置里加一份文本配置。

### 默认生图模型与模型注释

两个部署端变量（只影响前端展示，不含任何凭据）：

```yaml
DEFAULT_IMAGE_MODEL: gpt-image-2.6-flare
IMAGE_MODEL_NOTES: gpt-image-2.6-sunburst=顶级模型;gpt-image-2.6-flare=正常模型，适合日常使用
```

- `DEFAULT_IMAGE_MODEL` 决定**新建配置**的默认模型；已有配置不会被改动。留空时仍是内置的 `gpt-image-2.6-sunburst`。
- `IMAGE_MODEL_NOTES` 用分号分隔条目、等号分隔模型与注释，注释里可以带逗号。模型名**不区分大小写**（`gpt-image-2.6-Flare` 与 `gpt-image-2.6-flare` 共用一条注释）。
- 命中注释后，首页模型下拉会显示为 `gpt-image-2.6-flare （正常模型，适合日常使用）`；下拉选中的值仍是纯模型 ID，不会把注释发给接口。
- 一个配置里可以填多个模型（逗号分隔），下拉会逐个显示并各自匹配注释。

**docker compose 示例**（完整版见 [`deploy/docker-compose.example.yml`](deploy/docker-compose.example.yml)）

```yaml
services:
  gpt-image-playground:
    image: ghcr.io/tjsky/gpt_image_playground:latest
    restart: unless-stopped
    ports: ["8080:80"]
    environment:
      DEFAULT_API_URL: https://api.example.com/v1    # 前端可见的假地址，随便填
      DEFAULT_API_KEY: sk-fake-please-change         # 前端可见的假 KEY
      # ① 双 KEY：文本与生图分开
      API_PROXY_URL: https://cf.api.fan/v1
      API_PROXY_KEY: sk-real-image-key
      TEXT_API_URL: https://api.deepseek.com/v1
      TEXT_API_KEY: sk-real-text-key
      # ② 单 KEY：把上面两行留空即可，文本会自动复用生图上游
      # 预置文本配置，让访客开箱即用（留空则不预置）
      DEFAULT_TEXT_MODEL: deepseek-flash
      ENABLE_API_PROXY: "true"
      LOCK_API_PROXY: "false"
    volumes:
      - ./relay/api-target.conf:/etc/nginx/relay/api-target.conf:ro
      - ./relay/image-allow.conf:/etc/nginx/relay/image-allow.conf:ro
```

**管理中转站（推荐：挂载配置文件，`reload` 生效，不用重建镜像）**

1. 复制 [`deploy/relay/api-target.conf.example`](deploy/relay/api-target.conf.example) 为 `relay/api-target.conf`，按注释填 `$relay_image_*` / `$relay_text_*` 四行（`chmod 600`，不要提交到 git）。
2. 复制 [`deploy/relay/image-allow.conf.example`](deploy/relay/image-allow.conf.example) 为 `relay/image-allow.conf`，填中转站图片 CDN 域名白名单。
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

**安全提醒**

- 代理对访客开箱即用，等于把额度开放给所有能访问站点的人：建议外层加 Cloudflare Access 或 Nginx Basic Auth，并留意上游用量。
- 已内置：路径白名单（仅 `images/generations`、`images/edits`、`images/tasks/*`、`responses`、`tasks/*`）、每 IP 限流、图片代理仅允许 https 且拦截环回/内网地址。
- `X-Api-Kind` 只是分流标记，访客可以自己指定——它只会决定用哪套真实 KEY，不会拿到 KEY 本身。
- 若前面还有 Cloudflare，限流看到的是回源 IP，需另配 realip 才能按真实访客限流。

**自检命令**

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

以下变量适用于所有部署方式。使用时注意：

- 构建时变量需在构建前设置。
- Docker 使用去掉 `VITE_` 前缀的同名变量，在容器启动时读取。
- Docker 和客户端的专用变量见各自的部署方式。

| 构建时变量 | Docker 变量 | 说明 |
|------|------|------|
| `VITE_DEFAULT_API_URL` | `DEFAULT_API_URL` | 预置配置，见下文 |
| `VITE_LOCK_PRESET_CONFIG_PARAMS=true` | `LOCK_PRESET_CONFIG_PARAMS=true` | 锁定预置配置中除 API Key 外的参数，禁止编辑随预置引入的自定义供应商；当前锁定配置引用的供应商解除引用后才能删除 |
| `VITE_PREVENT_PRESET_CONFIG_DELETION=true` | `PREVENT_PRESET_CONFIG_DELETION=true` | 禁止删除预置配置及随预置引入的自定义供应商，不锁定参数，普通配置不受影响 |
| `VITE_SHOW_PRESET_CONFIG_ONLY=true` | `SHOW_PRESET_CONFIG_ONLY=true` | 只允许使用当前预置配置，禁止创建、复制、删除、拖动配置，禁止切换供应商和管理自定义供应商；未开启锁定时参数仍可编辑，API Key 始终可编辑 |
| `VITE_SHOW_CONFIG_CHANGE_DIALOG=false` | `SHOW_CONFIG_CHANGE_DIALOG=false` | 关闭链接导入配置时的变更确认弹窗，直接导入；默认开启，已有相同配置始终不弹窗 |
| `VITE_DEFAULT_UI_FONT` | `DEFAULT_UI_FONT` | 默认界面字体：`builtin`（内置，默认）、`system`（系统字体）或本机已安装的字体名称 |
| `VITE_DEFAULT_MONO_FONT` | `DEFAULT_MONO_FONT` | 默认代码字体，取值规则同 `VITE_DEFAULT_UI_FONT` |
| `VITE_BUILTIN_FONT_SOURCE` | `BUILTIN_FONT_SOURCE` | 内置字体来源：`cdn`（默认，公共 CDN）或 `local`（[`fonts/`](fonts) 目录中的文件） |
| `VITE_DEFAULT_API_KEY` | `DEFAULT_API_KEY` | 前端展示的「假 KEY」，仅用于 Nginx 校验站点代理，泄露无价值 |
| — | `API_PROXY_URL` | 真实上游地址，**只在容器内**，不要写进任何 `VITE_` 变量 |
| — | `API_PROXY_KEY` | 真实上游 KEY，**只在容器内** |
| — | `TEXT_API_URL` | 文本上游地址，**只在容器内**；留空则文本请求复用 `API_PROXY_URL` |
| — | `TEXT_API_KEY` | 文本上游 KEY，**只在容器内**；与 `TEXT_API_URL` 需成对出现 |
| `VITE_DEFAULT_TEXT_MODEL` | `DEFAULT_TEXT_MODEL` | 预置文本配置的模型名（如 `deepseek-flash`），设置后访客开箱即用 Agent；留空不预置 |
| `VITE_DEFAULT_TEXT_MODEL_NAME` | `DEFAULT_TEXT_MODEL_NAME` | 预置文本配置的显示名，默认「默认（文本）」 |
| `VITE_DEFAULT_IMAGE_MODEL` | `DEFAULT_IMAGE_MODEL` | 默认生图模型（新建配置时使用），留空用内置 `gpt-image-2.6-sunburst` |
| `VITE_IMAGE_MODEL_NOTES` | `IMAGE_MODEL_NOTES` | 模型注释，格式 `模型名=注释;模型名=注释`；模型名不区分大小写，显示在首页模型下拉里 |
| — | `IMAGE_PROXY_ALLOW_HOSTS` | 图片代理域名白名单，逗号分隔，如 `cdn.example.com,files.example.com` |

> 旧变量 `VITE_SHOW_DEFAULT_CONFIG_ONLY`／`SHOW_DEFAULT_CONFIG_ONLY` 仍可使用，等同于对应的 `SHOW_PRESET_CONFIG_ONLY`。

---

<a id="preset-config"></a>
## 📋 预置配置

`VITE_DEFAULT_API_URL` 支持三种写法。

**1. API 地址**

```dotenv
VITE_DEFAULT_API_URL=https://api.openai.com/v1
```

适合只提供一个配置的部署：

- 自动创建 ID 为 `default-openai` 的 OpenAI 兼容预置配置，模型、超时等使用应用默认值。
- 地址末尾带 `/` 时直接拼接接口，不补 `/v1`。
- 之后改用 JSON 或导入链接时，把 `id` 设为 `default-openai` 即可继续更新这个配置。

**2. API 地址 + 查询参数**

```dotenv
VITE_DEFAULT_API_URL=https://api.openai.com/v1?model=gpt-image-2.6-sunburst&apiMode=images
```

在地址后追加参数，预填 Key、模型等字段。可用参数与下文 [URL 传参快速填充](#url-quick-fill) 相同（`profileId` 除外）。

**3. 完整 JSON**

需要预置多个配置、自定义供应商或 Agent 时，按下文 JSON 格式编写，再用以下任一方式提供：

- **仓库内或本地文件（推荐）**：填写相对项目根目录的路径，如 `./gpt-image-config.example.json`。Docker 中填写容器内路径，宿主机文件需挂载到容器内。
- **远程文件**：填写以 `.json` 结尾的 HTTP／HTTPS 地址，只需部署服务器能访问（可位于内网），用户浏览器不必能访问。
- **导入链接**：在本站配置好后，复制配置的导入链接（含 `?settings=` 参数，不勾选“New API 变量配置”）。链接只包含当前选中的配置及其关联的自定义供应商。

```dotenv
VITE_DEFAULT_API_URL=./gpt-image-config.example.json
VITE_DEFAULT_API_URL=https://example.com/gpt-image-config.json
VITE_DEFAULT_API_URL=https://你的域名?settings=%7B%22profiles%22%3A%5B...%5D%7D
```

文件路径和远程地址会在构建、开发服务器启动或容器启动时读取，并内嵌到页面中。

**重新部署时**

- **参数更新**：API 地址、模型、超时等与上次部署快照比较。部署值变化时覆盖一次本地值，之后保留用户修改，直到部署值再次变化。
- **API Key**：始终由用户在本地管理，重新部署不覆盖。
- **排序与删除**：预置配置可拖动；预置配置和预置供应商均可删除，删除后重新部署不会恢复。需要锁定参数或禁止删除时，使用上文的限制变量。
- **下线预置清理**：部署端移除某个预置后，若用户未修改过且无历史任务引用，自动从本地删除；否则转为普通配置保留。
- **失效供应商清理**：随预置引入的自定义供应商不再被任何配置使用、且从未被用户修改时，自动清理。

<a id="preset-config-json"></a>
### JSON 格式

顶层字段：

- **`profiles`**（数组）：预置的 API 配置列表，每项对应用户配置列表中的一个配置。
- **`customProviders`**（可选数组）：自定义供应商定义，见下文 [自定义供应商](#custom-provider-config)。只使用内置供应商时可省略。
- **`agent`**（可选对象）：Agent 的独立 API 模式及文本、图像配置选择，见下方示例。

`profiles` 中每项的字段：

| 字段 | 必填 | 说明 |
|------|------|------|
| `id` | 定向更新时填写 | 配置标识，见表下说明。 |
| `name` | 是 | 配置名称。 |
| `description` | 否 | 配置说明，支持 Markdown，显示在“当前配置”下方的说明卡片中。 |
| `provider` | 是 | `"openai"`（OpenAI 兼容）、`"google"`（Google）、`"xai"`（xAI）、`"sb2api-async"`（sub2api 异步）、`"fal"`（fal.ai），或 `customProviders` 中的供应商 ID。 |
| `baseUrl` | 是 | API 基础地址，末尾 `/` 的规则见表下说明；fal.ai 可留空。 |
| `apiKey` | 否 | API Key。建议省略，由用户自行填写。 |
| `model` | 是 | 模型 ID。多个模型以逗号分隔，默认使用第一个，用户可在首页切换。 |
| `imageGenerationModel` | 否 | Responses API 的 `image_generation` 工具模型，默认 `gpt-image-2.6-sunburst`，也可用 `gpt-image-2.6-flare`；留空时不发送，使用 API 默认值。 |
| `apiMode` | 否 | `"images"` 或 `"responses"`，默认 `"images"`。 |
| `svgModel` | 否 | GPT Image 2.6 输出 SVG 时负责编写 SVG 的文本模型，默认 `gpt-6.1-sol`。 |
| `isDefault` | 否 | 有多个配置时为默认项设置 `true`（只能有一个），首次使用时自动选中；只有一个配置时不填。 |
| `timeout` | 否 | 请求超时秒数，默认 600。 |
| `apiProxy` | 否 | 是否走部署端 API 代理，默认 `false`。 |
| `transparentBackgroundMethod` | 否 | 透明背景实现方式：`"api"`（API 原生）或 `"local"`（本地后处理），默认值见表下说明。 |

补充说明：

- **`id`**：之后的链接（查询参数 `profileId`、`settings` 链接）或预置 JSON 携带相同 ID 时，直接更新该配置而非新建。应用内普通分享链接会省略此字段。
- **`baseUrl`**：未以 `/` 结尾时按 OpenAI 规则补齐 `/v1`（Google 补齐 `/v1beta`）；以 `/` 结尾时直接基于该地址请求。
- **`transparentBackgroundMethod` 默认值**：OpenAI 兼容和 fal.ai 为 `"api"`；自定义供应商的生成和编辑请求都映射了 `$params.background` 时为 `"api"`，否则为 `"local"`。

### 示例：仅 OpenAI 兼容

```json
{
  "profiles": [
    {
      "id": "my-openai",
      "name": "我的 OpenAI 配置",
      "description": "使用前请阅读 [接口说明](https://example.com/docs)。",
      "provider": "openai",
      "baseUrl": "https://api.openai.com/v1",
      "model": "gpt-image-2.6-sunburst"
    }
  ]
}
```

### 示例：OpenAI 兼容 + sub2api + fal.ai 多配置

```json
{
  "profiles": [
    {
      "id": "openai-main",
      "name": "OpenAI",
      "provider": "openai",
      "baseUrl": "https://api.openai.com/v1",
      "model": "gpt-image-2.6-sunburst",
      "isDefault": true
    },
    {
      "id": "sub2api-profile",
      "name": "sub2api 异步",
      "provider": "sb2api-async",
      "baseUrl": "https://api.example.com/v1",
      "model": "gpt-image-2.6-sunburst"
    },
    {
      "id": "fal-profile",
      "name": "fal.ai",
      "provider": "fal",
      "baseUrl": "",
      "model": "openai/gpt-image-2"
    }
  ]
}
```

### 示例：预置 Agent 配置

`agent.apiConfigMode` 决定 Agent 是否使用独立的 API 配置：

- **`off`**：沿用当前 API 配置。
- **`native`**：文本模型通过 Responses API 调用 `image_generation` 工具生成图片。
- **`hybrid`**：文本模型调用自定义工具，再由图像模型生成图片，适用于文本模型不支持原生图像工具的情况。

```json
{
  "profiles": [
    {
      "id": "default-openai",
      "name": "图像配置",
      "provider": "openai",
      "baseUrl": "https://api.example.com/v1",
      "model": "image-model",
      "apiMode": "images",
      "isDefault": true
    },
    {
      "id": "default-openai-agent",
      "name": "文本配置",
      "provider": "openai",
      "baseUrl": "https://api.example.com/v1",
      "model": "text-model",
      "apiMode": "responses"
    }
  ],
  "agent": {
    "apiConfigMode": "hybrid",
    "textProfileId": "default-openai-agent",
    "imageProfileId": "default-openai"
  }
}
```

- `textProfileId` 和 `imageProfileId` 引用 `profiles` 中的 ID。
- 文本配置须使用 OpenAI 兼容的 Responses API；图像配置可使用任意支持的供应商。
- `agent` 及其三个字段都可省略，随部署更新和锁定的规则与预置配置相同。

完整示例见 [`gpt-image-config.agent.example.json`](gpt-image-config.agent.example.json)。

---

<a id="custom-provider-config"></a>
## 🔌 自定义供应商

API 不是标准 OpenAI 格式时，在预置 JSON 的 `customProviders` 中定义请求和响应结构。每个供应商需有唯一的 `id`，由 `profiles` 中的 `provider` 字段引用。

接口不在 `/v1` 路径下时，将 `baseUrl` 设为以 `/` 结尾。例如 `baseUrl` 为 `https://api.example.com/`、`submit.path` 为 `api/image-tasks` 时，实际请求地址为 `https://api.example.com/api/image-tasks`。

`modelOverrides` 可按模型 ID（支持 `*` 通配符）配置不同接口，路径支持 `{model}` 占位符。完整字段见 [自定义供应商 LLM 提示词](docs/custom-provider-llm-prompt.md)。

**获取供应商定义**

- **AI 生成**：在本站的 **「设置 → API 配置 → 供应商类型 → 创建自定义供应商 → AI 一键生成与导入」** 中粘贴第三方 API 文档生成配置，再复制该配置的导入链接作为预置值。
- **手动生成**：将 [自定义供应商 LLM 提示词](docs/custom-provider-llm-prompt.md) 和第三方 API 文档发给任意 LLM，获取完整 JSON。

**完整 JSON 示例（异步任务供应商）**

```json
{
  "customProviders": [
    {
      "id": "custom-example-task",
      "name": "示例异步任务供应商",
      "submit": {
        "path": "images/generations",
        "method": "POST",
        "contentType": "json",
        "body": {
          "model": "$profile.model",
          "prompt": "$prompt",
          "size": "$params.size",
          "quality": "$params.quality",
          "output_format": "$params.output_format",
          "output_compression": "$params.output_compression",
          "n": "$params.n",
          "image_urls": "$inputImages.dataUrls"
        },
        "taskIdPath": "data.0.task_id"
      },
      "poll": {
        "path": "tasks/{task_id}",
        "method": "GET",
        "intervalSeconds": 5,
        "statusPath": "data.status",
        "successValues": ["completed"],
        "failureValues": ["failed", "cancelled"],
        "errorPath": "data.error.message",
        "result": {
          "imageUrlPaths": ["data.result.images.*.url.*"],
          "b64JsonPaths": []
        }
      }
    }
  ],
  "profiles": [
    {
      "id": "example-profile",
      "name": "示例异步任务供应商",
      "provider": "custom-example-task",
      "baseUrl": "https://api.example.com/v1",
      "model": "gpt-image-2.6-sunburst",
      "apiMode": "images"
    }
  ]
}
```

---

<a id="url-quick-fill"></a>
## 🛠️ URL 传参快速填充

通过 URL 查询参数快速填入 OpenAI 兼容配置，适合创建书签或集成分享。

| 参数 | 说明 | 示例 |
|------|------|------|
| `apiUrl` | API Base URL | `?apiUrl=https://api.example.com/v1` |
| `apiKey` | API Key | `?apiKey=sk-xxxx` |
| `model` | 模型 ID，多个模型以逗号分隔，可在首页切换 | `?model=gpt-image-2.6-sunburst,gpt-image-2` |
| `imageGenerationModel` | Responses API 的图像生成工具模型，留空使用 API 默认值 | `?imageGenerationModel=gpt-image-2.6-sunburst` |
| `apiMode` | `images` 或 `responses`，默认 `images` | `?apiMode=responses` |
| `profileName` | 配置名称，默认“URL 参数配置” | `?profileName=我的配置` |
| `reasoningEffort` | Responses API 推理强度 | `?reasoningEffort=high` |
| `codexCli` | Codex CLI 兼容模式 | `?codexCli=true` |
| `streamImages` | 流式传输 | `?streamImages=true` |
| `streamPartialImages` | 中间步骤图像数（需配合 streamImages） | `?streamPartialImages=2` |
| `profileId` | 目标配置 ID；匹配到同 ID 配置时直接更新 | `?profileId=my-service` |
| `transparentBackgroundMethod` | 透明背景实现方式：`api`（原生）或 `local`（本地后处理） | `?transparentBackgroundMethod=local` |

在客户端中，复制带 `apiUrl` 或 `settings` 参数的导入链接后切回客户端，即会提示导入。

集成示例（New API 聊天系统）：

```text
https://gpt-image-playground.cooksleep.dev?apiUrl={address}&apiKey={key}&model={model}
```

```text
https://cooksleep.github.io/gpt_image_playground?apiUrl={address}&apiKey={key}&model={model}
```

---

<a id="announcements"></a>
## 📢 公告卡片

[`public/announcements.json`](public/announcements.json) 定义启动时显示的公告卡片，随应用一起打包。

- **添加公告**：在数组中追加一个对象，媒体文件放在 `public/announcements/` 中。
- **关闭公告**：自行部署时把该文件改为 `[]`。

| 字段 | 说明 |
|------|------|
| `id` | 必填，唯一标识；已读记录按 id 保存，换 id 才会再次提示 |
| `title` | 必填，标题 |
| `content` | 必填，Markdown 正文 |
| `note` | 可选，正文下方的次要说明（纯文本） |
| `when` | 可选，显示条件，缺省时总是显示 |
| `action` | 可选，主按钮 `{ "label": "下载客户端", "url": "https://..." }` |
| `media` | 可选，卡片顶部的媒体 `{ "type": "html" \| "image", "src": "announcements/xxx.html", "aspectRatio": "16/9" }` |

`media.src` 为不以 `/` 开头的相对路径；`html` 页面需引用同目录下的外部 `.css`、`.js` 文件。

`when` 是一个对象，每个键都要满足：

- 值可以是字面量（等于）、数组（等于其中之一）或运算对象 `{ "eq" | "ne" | "gt" | "gte" | "lt" | "lte" | "in": 值 }`。
- 可用 `all`、`any`、`not` 组合条件。
- 条件写错时该条公告不显示，并在控制台提示。

| 变量 | 取值 |
|------|------|
| `platform` | `"web"` 或 `"client"` |
| `os` | `"windows"`、`"macos"`、`"linux"`、`"android"`、`"ios"` 或 `"other"` |
| `language` | 浏览器语言，如 `"zh-CN"` |
| `version` | 当前应用版本，如 `{ "gte": "0.8.0" }` |
| `imageCount` | 画廊中成功生成的图片数 |
| `taskCount` | 画廊任务数 |
| `standalone` | 网页版是否以 PWA 方式运行 |
| `now` | 当前时间，写带时区的 ISO 时间，如 `{ "lt": "2026-12-01T00:00:00+08:00" }` |

示例：

```json
[
  { "id": "web-windows", "title": "网页版 Windows 用户", "content": "……", "when": { "platform": "web", "os": "windows" } },
  { "id": "power-user", "title": "已生成超过 100 张图片", "content": "……", "when": { "imageCount": { "gt": 100 } } }
]
```

---

## 💻 技术栈

<div align="center">
  <br>
  <a href="https://react.dev/"><img src="https://img.shields.io/badge/React_19-20232A?style=for-the-badge&logo=react&logoColor=61DAFB" alt="React 19" /></a>
  <a href="https://www.typescriptlang.org/"><img src="https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" /></a>
  <a href="https://vite.dev/"><img src="https://img.shields.io/badge/Vite-B73BFE?style=for-the-badge&logo=vite&logoColor=FFD62E" alt="Vite" /></a>
  <a href="https://tailwindcss.com/"><img src="https://img.shields.io/badge/Tailwind_CSS_3-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white" alt="Tailwind CSS 3" /></a>
  <a href="https://zustand.docs.pmnd.rs/"><img src="https://img.shields.io/badge/Zustand-764ABC?style=for-the-badge&logo=react&logoColor=white" alt="Zustand" /></a>
  <br>
  <br>
</div>

## 🔤 字体许可

本项目内置以下两款字体，由 `VITE_BUILTIN_FONT_SOURCE` 决定从公共 CDN 加载还是使用 [`fonts/`](fonts) 目录中的字体文件。完整许可文本位于 [`third-party-licenses/`](third-party-licenses)，也可在应用的 **「设置 → 关于 → 第三方许可」** 中查看。

| 字体 | 版权方 | 许可 | 项目地址 | 许可文件 |
|------|------|------|------|------|
| HarmonyOS Sans SC | Huawei Device Co., Ltd. | HarmonyOS Sans Fonts License Agreement | [HarmonyOS 设计资源](https://developer.huawei.com/consumer/cn/design/resource/)，[许可证（License）](https://github.com/openharmony/resources/blob/master/LICENSE_Fonts) | [`third-party-licenses/HarmonyOS-Sans-LICENSE.txt`](third-party-licenses/HarmonyOS-Sans-LICENSE.txt) |
| Maple Mono NF CN | The Maple Mono Project Authors | SIL Open Font License 1.1 | [subframe7536/maple-font](https://github.com/subframe7536/maple-font) | [`third-party-licenses/MapleMono-LICENSE.txt`](third-party-licenses/MapleMono-LICENSE.txt) |

- HarmonyOS Sans SC 为官方未经修改的 TTF 文件（Regular、Medium、Bold）。
- Maple Mono NF CN 取自官方 v7.9 Release 的 Regular 字重，按 OFL 转换为 woff2 格式，未改动字形和名称。

## 📄 许可证 & 致谢

本项目基于 [MIT License](LICENSE) 开源。

特别致谢：[LINUX DO](https://linux.do)

## ⭐ Star History

<div align="center">
  <a href="https://www.star-history.com/?repos=CookSleep%2Fgpt_image_playground&type=date&legend=top-left">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=CookSleep/gpt_image_playground&type=date&theme=dark&legend=top-left&sealed_token=YDhR-bhWDaCuWPSxXgtqShoQoM84wroDOtJOM_4TtQsdxIYcQoVPIykb3dHxXo__YPI7b2HlcrMitDbXkJw0dQi68bJOx5xCCqyz8qVdokdcPKMOSbNWOhsDYv6FKKQW40xKkkOqjme8AnR-T9z3i6bq83j47rR6WiNC1n6uVaVf3Ksm8JOf0y9lpXpj" />
      <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=CookSleep/gpt_image_playground&type=date&legend=top-left&sealed_token=YDhR-bhWDaCuWPSxXgtqShoQoM84wroDOtJOM_4TtQsdxIYcQoVPIykb3dHxXo__YPI7b2HlcrMitDbXkJw0dQi68bJOx5xCCqyz8qVdokdcPKMOSbNWOhsDYv6FKKQW40xKkkOqjme8AnR-T9z3i6bq83j47rR6WiNC1n6uVaVf3Ksm8JOf0y9lpXpj" />
      <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=CookSleep/gpt_image_playground&type=date&legend=top-left&sealed_token=YDhR-bhWDaCuWPSxXgtqShoQoM84wroDOtJOM_4TtQsdxIYcQoVPIykb3dHxXo__YPI7b2HlcrMitDbXkJw0dQi68bJOx5xCCqyz8qVdokdcPKMOSbNWOhsDYv6FKKQW40xKkkOqjme8AnR-T9z3i6bq83j47rR6WiNC1n6uVaVf3Ksm8JOf0y9lpXpj" />
    </picture>
  </a>
</div>
