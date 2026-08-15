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
  return req('/api/table-storage/domains');
}

export async function getTables(domain) {
  return req(`/api/table-storage/tables?domain=${encodeURIComponent(domain)}`);
}

// ── Records ───────────────────────────────────────────────────────────────────

export async function getRecords(domain, table) {
  return req(`/api/table-storage/records?domain=${encodeURIComponent(domain)}&table=${encodeURIComponent(table)}`);
}

export async function addRecord(domain, table, payload) {
  return req(`/api/table-storage/records?domain=${encodeURIComponent(domain)}&table=${encodeURIComponent(table)}`, 'POST', payload);
}

export async function deleteRecord(domain, table, partitionKey, rowKey) {
  return req(`/api/table-storage/records?domain=${encodeURIComponent(domain)}&table=${encodeURIComponent(table)}&partitionKey=${encodeURIComponent(partitionKey)}&rowKey=${encodeURIComponent(rowKey)}`, 'DELETE');
}

export async function deleteRecords(domain, table, records) {
  return req(`/api/table-storage/records/bulk-delete?domain=${encodeURIComponent(domain)}&table=${encodeURIComponent(table)}`, 'POST', { records });
}

export async function clearTable(domain, table) {
  return req(`/api/table-storage/records/clear?domain=${encodeURIComponent(domain)}&table=${encodeURIComponent(table)}`, 'DELETE');
}

// ── Audit ─────────────────────────────────────────────────────────────────────

export async function getAuditLogs(page = 0, size = 10) {
  return req(`/api/table-storage/audit?page=${page}&size=${size}`);
}
