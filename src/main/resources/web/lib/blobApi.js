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
  return req('/api/blob/domains');
}

export async function getContainers(domain) {
  return req(`/api/blob/containers?domain=${encodeURIComponent(domain)}`);
}

// ── Blobs ─────────────────────────────────────────────────────────────────────

export async function getBlobs(domain, container) {
  return req(`/api/blob/blobs?domain=${encodeURIComponent(domain)}&container=${encodeURIComponent(container)}`);
}

export async function uploadBlob(domain, container, file) {
  const formData = new FormData();
  formData.append('domain', domain);
  formData.append('container', container);
  formData.append('file', file);
  const res = await fetch('/api/blob/upload', { method: 'POST', body: formData });
  const text = await res.text();
  if (!res.ok) throw new Error(text || `HTTP ${res.status}`);
  return text ? JSON.parse(text) : null;
}

export async function downloadBlob(domain, container, blobName) {
  const res = await fetch(`/api/blob/download?domain=${encodeURIComponent(domain)}&container=${encodeURIComponent(container)}&blob=${encodeURIComponent(blobName)}`);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.blob();
}

export async function deleteBlob(domain, container, blobName) {
  return req(`/api/blob/blobs/${encodeURIComponent(blobName)}?domain=${encodeURIComponent(domain)}&container=${encodeURIComponent(container)}`, 'DELETE');
}

export async function deleteBlobs(domain, container, blobNames) {
  return req(`/api/blob/blobs/bulk-delete?domain=${encodeURIComponent(domain)}&container=${encodeURIComponent(container)}`, 'POST', { blobs: blobNames });
}

export async function clearSpace(domain, container) {
  return req(`/api/blob/blobs/clear?domain=${encodeURIComponent(domain)}&container=${encodeURIComponent(container)}`, 'DELETE');
}

// ── Audit ─────────────────────────────────────────────────────────────────────

export async function getAuditLogs(page = 0, size = 10) {
  return req(`/api/blob/audit?page=${page}&size=${size}`);
}
