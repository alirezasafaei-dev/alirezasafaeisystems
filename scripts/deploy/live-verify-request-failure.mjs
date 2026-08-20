export function isExpectedNextPrefetchAbort({ method, url, errorText }) {
  if (method !== 'GET' || errorText !== 'net::ERR_ABORTED') {
    return false
  }

  try {
    return new URL(url).searchParams.has('_rsc')
  } catch {
    return false
  }
}
