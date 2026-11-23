import { readRuntimeEnv } from './runtimeEnv'

/**
 * 部署端配置的默认生图模型（DEFAULT_IMAGE_MODEL）。
 * 留空时前端沿用内置默认（gpt-image-2.6-sunburst）。
 */
export const DEFAULT_IMAGE_MODEL = readRuntimeEnv(import.meta.env.VITE_DEFAULT_IMAGE_MODEL)

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
