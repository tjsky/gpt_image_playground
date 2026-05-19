import { getActiveApiProfile, getCustomProviderDefinition } from './apiProfiles'
import { callFalAiImageApi } from './falAiImageApi'
import { callOpenAICompatibleImageApi } from './openaiCompatibleImageApi'
import type { CallApiOptions, CallApiResult } from './imageApiShared'
import { RUNTIME_ENV } from './runtimeEnv'

export type { CallApiOptions, CallApiResult } from './imageApiShared'
export { normalizeBaseUrl } from './devProxy'

export async function callImageApi(opts: CallApiOptions): Promise<CallApiResult> {
  let profile = getActiveApiProfile(opts.settings)

  if (
    RUNTIME_ENV.API_PROXY_AVAILABLE &&
    profile.provider === 'openai' &&
    profile.baseUrl === RUNTIME_ENV.DEFAULT_API_URL &&
    profile.apiKey === RUNTIME_ENV.DEFAULT_API_KEY
  ) {
    profile = {
      ...profile,
      baseUrl: `${window.location.origin}/api-proxy`,
    }
  }

  if (profile.provider === 'fal') return callFalAiImageApi(opts, profile)

  return callOpenAICompatibleImageApi(opts, profile, getCustomProviderDefinition(opts.settings, profile.provider))
}
