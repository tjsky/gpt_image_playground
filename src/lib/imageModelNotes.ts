import { readRuntimeEnv } from './runtimeEnv'

/**
 * 把 `;`、`；`、`,`、`，` 或换行分隔的模型列表归一化为逗号分隔（trim、去空、保序去重）。
 * 前端内部统一用逗号表示「一个配置里的多个模型」。
 */
export function normalizeImageModelList(raw: string): string {
  const seen = new Set<string>()
  const models: string[] = []
  for (const part of raw.split(/[;；,，\n\r]+/)) {
    const model = part.trim()
    if (!model || seen.has(model)) continue
    seen.add(model)
    models.push(model)
  }
  return models.join(',')
}

/** 取模型列表的第一项：用于 imageGenerationModel 这类只能填单个模型的字段 */
export function getPrimaryImageModel(modelList: string): string {
  return modelList.split(',')[0]?.trim() ?? ''
}

/**
 * 部署端配置的默认生图模型（DEFAULT_IMAGE_MODEL）。
 * 支持用 `;` 分隔多个模型（如 `gpt-image-2.6-flare;gpt-image-2.6-sunburst`），
 * 默认选中第一个，其余可在首页切换。留空时前端沿用内置默认（gpt-image-2.6-sunburst）。
 */
export const DEFAULT_IMAGE_MODEL = normalizeImageModelList(readRuntimeEnv(import.meta.env.VITE_DEFAULT_IMAGE_MODEL))

/**
 * 模型注释配置（IMAGE_MODEL_NOTES），格式：`模型名=注释;模型名=注释`。
 * 模型名不区分大小写；注释里可以带逗号，条目之间用分号或换行分隔。
 */
const RAW_IMAGE_MODEL_NOTES = readRuntimeEnv(import.meta.env.VITE_IMAGE_MODEL_NOTES)

const imageModelNotes = (() => {
  const notes = new Map<string, string>()
  for (const entry of RAW_IMAGE_MODEL_NOTES.split(/[;；\n\r]+/)) {
    const separator = entry.indexOf('=')
    if (separator <= 0) continue
    const model = entry.slice(0, separator).trim().toLowerCase()
    const note = entry.slice(separator + 1).trim()
    if (model && note) notes.set(model, note)
  }
  return notes
})()

export function hasImageModelNotes(): boolean {
  return imageModelNotes.size > 0
}

/** 按模型名（不区分大小写）取注释，没有配置时返回空串 */
export function getImageModelNote(model: string): string {
  return imageModelNotes.get(model.trim().toLowerCase()) ?? ''
}

/** 下拉里展示的文案：配置了注释时追加「（注释）」 */
export function formatImageModelLabel(model: string): string {
  const note = getImageModelNote(model)
  return note ? `${model} （${note}）` : model
}
