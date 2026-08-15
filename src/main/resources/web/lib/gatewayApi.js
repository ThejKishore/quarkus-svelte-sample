const BASE = 'http://localhost:8080';

async function req(path, method = 'GET', body = null) {
  const opts = { method };
  if (body !== null) {
    opts.headers = { 'Content-Type': 'application/json' };
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, opts);
  const text = await res.text();
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

// ── Routes ──────────────────────────────────────────────────────────────────

export async function listRoutes() {
  try {
    const res = await fetch(`${BASE}/gateway/admin/routes`);
    if (!res.ok) return [];
    return await res.json();
  } catch {
    return [];
  }
}

export async function createRoute(route) {
  return req('/gateway/admin/routes', 'POST', route);
}

export async function updateRoute(id, route) {
  return req(`/gateway/admin/routes/${id}`, 'PUT', route);
}

export async function enableRoute(id) {
  return req(`/gateway/admin/routes/${id}/enable`, 'PATCH');
}

export async function disableRoute(id) {
  return req(`/gateway/admin/routes/${id}/disable`, 'PATCH');
}

export async function deleteRoute(id) {
  return req(`/gateway/admin/routes/${id}`, 'DELETE');
}

// ── Health & reload ──────────────────────────────────────────────────────────

export async function getHealth() {
  try {
    const res = await fetch(`${BASE}/gateway/health`);
    return await res.json();
  } catch {
    return null;
  }
}

export async function reloadGateway() {
  return req('/gateway/admin/reload', 'POST');
}

// ── Audit logs ───────────────────────────────────────────────────────────────

export async function getChangeLogs(limit = 100) {
  try {
    const res = await fetch(`${BASE}/gateway/admin/change-logs?limit=${limit}`);
    const data = await res.json();
    return data.logs ?? [];
  } catch {
    return [];
  }
}
