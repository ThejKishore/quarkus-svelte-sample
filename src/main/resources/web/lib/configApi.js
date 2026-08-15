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

// ── Metadata ─────────────────────────────────────────────────────────────────

export async function getMetadata() {
  return req('/api/config/meta');
}

// ── Properties ───────────────────────────────────────────────────────────────

export async function getProperties(app, domain) {
  return req(`/api/config/properties/${domain}/${app}`);
}

export async function getConfigSyncInfo(app, domain) {
  return req(`/api/config/sync/${domain}/${app}`);
}

export async function addProperty(app, domain, payload) {
  return req(`/api/config/properties/${domain}/${app}`, 'POST', {
    propertyKey: payload.propertyKey,
    propertyValue: payload.propertyValue,
    createdBy: payload.createdBy ?? 'admin',
  });
}

export async function updateProperties(app, domain, payload) {
  return req(`/api/config/properties/${domain}/${app}`, 'PUT', payload);
}

export async function deleteProperty(app, domain, key) {
  return req(`/api/config/properties/${domain}/${app}/${key}`, 'DELETE');
}

// ── Onboarding ───────────────────────────────────────────────────────────────

export async function onboardService(domain, app, file) {
  const formData = new FormData();
  formData.append('domain', domain);
  formData.append('application', app);
  formData.append('file', file);
  const res = await fetch('/api/config/onboard', { method: 'POST', body: formData });
  const text = await res.text();
  if (!res.ok) throw new Error(text || `Onboarding failed: HTTP ${res.status}`);
  return text;
}

// ── Audit ─────────────────────────────────────────────────────────────────────

export async function getAuditHistory(app, domain, limit = 100) {
  return req(`/api/config/audit/${domain}/${app}?limit=${limit}`);
}
