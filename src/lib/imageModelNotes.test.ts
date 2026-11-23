import { afterEach, describe, expect, it, vi } from 'vitest'
import { getPrimaryImageModel, normalizeImageModelList } from './imageModelNotes'

describe('normalizeImageModelList', () => {
  it('接受分号、逗号、全角分隔符与换行', () => {
    expect(normalizeImageModelList('a;b')).toBe('a,b')
    expect(normalizeImageModelList('a；b')).toBe('a,b')
    expect(normalizeImageModelList('a,b')).toBe('a,b')
    expect(normalizeImageModelList('a，b')).toBe('a,b')
    expect(normalizeImageModelList('a\nb')).toBe('a,b')
  })

  it('去空白、丢空项、保序去重', () => {
    expect(normalizeImageModelList('  a ; ; b ;; a ')).toBe('a,b')
  })

  it('空输入返回空串', () => {
    expect(normalizeImageModelList('')).toBe('')
    expect(normalizeImageModelList('   ;  ')).toBe('')
  })
})

describe('getPrimaryImageModel', () => {
  it('取列表第一项', () => {
    expect(getPrimaryImageModel('gpt-image-2.6-flare,gpt-image-2.6-sunburst')).toBe('gpt-image-2.6-flare')
    expect(getPrimaryImageModel('gpt-image-2.6-flare')).toBe('gpt-image-2.6-flare')
  })

  it('空输入返回空串', () => {
    expect(getPrimaryImageModel('')).toBe('')
  })
})

describe('模型注释', () => {
  afterEach(() => {
    vi.unstubAllEnvs()
    vi.resetModules()
  })

  it('注释只在传入 formatImageModelLabel 时追加，且模型名不区分大小写', async () => {
    vi.stubEnv('VITE_IMAGE_MODEL_NOTES', 'gpt-image-2.6-sunburst=顶级模型;gpt-image-2.6-flare=正常模型，适合日常使用')
    vi.resetModules()
    const mod = await import('./imageModelNotes')

    expect(mod.getImageModelNote('GPT-Image-2.6-Sunburst')).toBe('顶级模型')
    expect(mod.formatImageModelLabel('gpt-image-2.6-flare')).toBe('gpt-image-2.6-flare （正常模型，适合日常使用）')
    expect(mod.formatImageModelLabel('unknown-model')).toBe('unknown-model')
  })

  it('没配注释时原样返回模型名', async () => {
    vi.stubEnv('VITE_IMAGE_MODEL_NOTES', '')
    vi.resetModules()
    const mod = await import('./imageModelNotes')

    expect(mod.hasImageModelNotes()).toBe(false)
    expect(mod.formatImageModelLabel('gpt-image-2.6-flare')).toBe('gpt-image-2.6-flare')
  })
})
