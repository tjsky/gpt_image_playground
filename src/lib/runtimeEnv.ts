export function readRuntimeEnv(value: string | undefined): string {
  return String.prototype.trim.call(value ?? '')
}

export const RUNTIME_ENV = {
  DEFAULT_API_URL: readRuntimeEnv(
    typeof import.meta.env !== 'undefined' ? import.meta.env.VITE_DEFAULT_API_URL : ''
  ),
  DEFAULT_API_KEY: readRuntimeEnv(
    typeof import.meta.env !== 'undefined' ? import.meta.env.VITE_DEFAULT_API_KEY : ''
  ),
  API_PROXY_AVAILABLE: readRuntimeEnv(
    typeof import.meta.env !== 'undefined' ? import.meta.env.VITE_API_PROXY_AVAILABLE : ''
  ) === 'true',
}