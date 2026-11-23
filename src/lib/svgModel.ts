import type { ApiProfile, AppSettings } from '../types'
import { DEFAULT_SVG_MODEL } from './imageModels'

/**
 * Agent 配置里的文本模型：只在 hybrid / native 模式下有值。
 * mode 为 off（未启用 Agent）或未选文本配置时返回空串。
 */
export function getAgentTextModel(settings?: Partial<AppSettings> | null): string {
  if (!settings || settings.agentApiConfigMode === 'off') return ''
  const profile = settings.profiles?.find((item) => item.id === settings.agentTextProfileId)
  return profile?.model?.trim() || ''
}

/**
 * 输出 SVG 时负责编写 SVG 的文本模型，优先级：
 * 1. 该配置里手填的「SVG 编写模型 ID」
 * 2. Agent 配置里的文本模型（混合 / 原生模式）
 * 3. 内置默认（gpt-6.1-sol）
 */
export function resolveSvgModel(
  profile: Pick<ApiProfile, 'svgModel'>,
  settings?: Partial<AppSettings> | null,
): string {
  const explicit = profile.svgModel?.trim()
  if (explicit) return explicit
  return getAgentTextModel(settings) || DEFAULT_SVG_MODEL
}
