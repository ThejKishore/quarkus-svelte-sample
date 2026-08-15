async function req(path, method = 'GET', body = null) {
  const opts = { method };
  if (body !== null) {
    opts.headers = { 'Content-Type': 'application/json' };
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(path, opts);
  const text = await res.text();
  if (!res.ok) throw new Error(text || `HTTP ${res.status}`);
  return text ? JSON.parse(text) : null;
}

// ── Metadata ──────────────────────────────────────────────────────────────────

export async function getDomains() {
  return req('/api/redis/domains');
}

export async function getServices(domain) {
  return req(`/api/redis/services?domain=${encodeURIComponent(domain)}`);
}

// ── Keys ──────────────────────────────────────────────────────────────────────

export async function getRedisKeys(domain, service) {
  return req(`/api/redis/keys?domain=${encodeURIComponent(domain)}&service=${encodeURIComponent(service)}`);
}

export async function addRedisKey(domain, service, payload) {
  return req(`/api/redis/keys?domain=${encodeURIComponent(domain)}&service=${encodeURIComponent(service)}`, 'POST', payload);
}

export async function deleteRedisKey(domain, service, keyName) {
  return req(`/api/redis/keys/${encodeURIComponent(keyName)}?domain=${encodeURIComponent(domain)}&service=${encodeURIComponent(service)}`, 'DELETE');
}

export async function deleteRedisKeys(domain, service, keyNames) {
  return req(`/api/redis/keys/bulk-delete?domain=${encodeURIComponent(domain)}&service=${encodeURIComponent(service)}`, 'POST', { keys: keyNames });
}

export async function clearAllRedisKeys(domain, service) {
  return req(`/api/redis/keys/clear?domain=${encodeURIComponent(domain)}&service=${encodeURIComponent(service)}`, 'DELETE');
}

// ── Audit ─────────────────────────────────────────────────────────────────────

export async function getAuditLogs(page = 0, size = 10) {
  return req(`/api/redis/audit?page=${page}&size=${size}`);
}
