<script>
  import { onMount } from 'svelte';
  import * as api from '../../../lib/blobApi.js';
  import { showToast } from '../../../lib/toastStore.js';
  import UploadBlobModal from './UploadModal.svelte';
  import ViewBlobModal from './ViewModal.svelte';

  const PAGE_SIZE = 10;

  let domains = $state([]);
  let containers = $state([]);
  let selectedDomain = $state('');
  let selectedContainer = $state('');

  let allBlobs = $state([]);
  let page = $state(0);
  let sortCol = $state('blobName');
  let sortDir = $state('asc');
  let selected = $state(new Set());
  let loaded = $state(false);
  let loading = $state(false);

  let showUploadModal = $state(false);
  let viewingBlob = $state(null);

  onMount(loadDomains);

  async function loadDomains() {
    try {
      domains = await api.getDomains();
    } catch (e) {
      showToast(`Failed to load domains: ${e.message}`, 'error');
    }
  }

  async function onDomainChange() {
    containers = [];
    selectedContainer = '';
    allBlobs = [];
    loaded = false;
    if (!selectedDomain) return;
    try {
      containers = await api.getContainers(selectedDomain);
    } catch (e) {
      showToast(`Failed to load containers: ${e.message}`, 'error');
    }
  }

  async function fetchBlobs() {
    if (!selectedDomain) { showToast('Please select a domain', 'warning'); return; }
    if (!selectedContainer) { showToast('Please select a container', 'warning'); return; }
    loading = true;
    try {
      allBlobs = await api.getBlobs(selectedDomain, selectedContainer);
      loaded = true;
      page = 0;
      selected = new Set();
    } catch (e) {
      showToast(`Failed to fetch blobs: ${e.message}`, 'error');
    } finally {
      loading = false;
    }
  }

  function setSort(col) {
    if (sortCol === col) { sortDir = sortDir === 'asc' ? 'desc' : 'asc'; }
    else { sortCol = col; sortDir = 'asc'; }
    page = 0;
  }

  let sortedBlobs = $derived((() => {
    const arr = [...allBlobs];
    arr.sort((a, b) => {
      const av = a[sortCol] ?? ''; const bv = b[sortCol] ?? '';
      return (av < bv ? -1 : av > bv ? 1 : 0) * (sortDir === 'asc' ? 1 : -1);
    });
    return arr;
  })());

  let totalPages = $derived(Math.max(1, Math.ceil(sortedBlobs.length / PAGE_SIZE)));
  let pageBlobs = $derived(sortedBlobs.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE));

  function sortIcon(col) {
    if (sortCol !== col) return 'fas fa-sort text-gray-300';
    return sortDir === 'asc' ? 'fas fa-sort-up text-blue-500' : 'fas fa-sort-down text-blue-500';
  }

  function toggleSelect(blobName) {
    const s = new Set(selected);
    if (s.has(blobName)) s.delete(blobName); else s.add(blobName);
    selected = s;
  }

  function toggleAll() {
    if (selected.size === pageBlobs.length) { selected = new Set(); }
    else { selected = new Set(pageBlobs.map(b => b.blobName)); }
  }

  async function deleteSelected() {
    if (selected.size === 0) { showToast('No blobs selected', 'warning'); return; }
    if (!confirm(`Delete ${selected.size} selected blob(s)?`)) return;
    try {
      await api.deleteBlobs(selectedDomain, selectedContainer, [...selected]);
      showToast(`${selected.size} blob(s) deleted`, 'success');
      await fetchBlobs();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  async function clearSpace() {
    if (!confirm('Delete ALL blobs in the selected container? This cannot be undone.')) return;
    try {
      await api.clearSpace(selectedDomain, selectedContainer);
      showToast('Container cleared', 'success');
      await fetchBlobs();
    } catch (e) {
      showToast(`Clear failed: ${e.message}`, 'error');
    }
  }

  async function deleteOne(blobName) {
    if (!confirm(`Delete blob "${blobName}"?`)) return;
    try {
      await api.deleteBlob(selectedDomain, selectedContainer, blobName);
      showToast(`Blob "${blobName}" deleted`, 'success');
      await fetchBlobs();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  async function downloadBlob(blobName) {
    try {
      const blob = await api.downloadBlob(selectedDomain, selectedContainer, blobName);
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url; a.download = blobName; a.click();
      URL.revokeObjectURL(url);
    } catch (e) {
      showToast(`Download failed: ${e.message}`, 'error');
    }
  }

  function formatSize(bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  }

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }
</script>

<div class="p-4 space-y-4">
  <!-- Section 1: Selectors -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div class="flex items-end gap-3 flex-wrap">
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Domain Name</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white min-w-[160px]"
          bind:value={selectedDomain}
          onchange={onDomainChange}
        >
          <option value="">— select domain —</option>
          {#each domains as d}
            <option value={d}>{d}</option>
          {/each}
        </select>
      </div>
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Container Name</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white min-w-[160px]"
          bind:value={selectedContainer}
          disabled={!selectedDomain}
        >
          <option value="">— select container —</option>
          {#each containers as c}
            <option value={c}>{c}</option>
          {/each}
        </select>
      </div>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 transition-colors disabled:opacity-50"
        onclick={fetchBlobs}
        disabled={loading}
      >
        <i class="fas fa-search {loading ? 'animate-spin' : ''}"></i>
        {loading ? 'Fetching…' : 'Fetch Blobs'}
      </button>
    </div>
  </div>

  <!-- Section 2: Blobs Table -->
  {#if loaded}
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-x-auto">
      <table class="min-w-full">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr>
            <th class="px-4 py-3">
              <input type="checkbox" checked={selected.size === pageBlobs.length && pageBlobs.length > 0} onchange={toggleAll} class="rounded" />
            </th>
            {#each [['blobName','Blob Name'],['blobSize','Blob Size'],['lastModified','Last Modified']] as [col, label]}
              <th
                class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider cursor-pointer select-none whitespace-nowrap hover:bg-gray-100"
                onclick={() => setSort(col)}
              >
                {label} <i class="{sortIcon(col)} ml-1 text-xs"></i>
              </th>
            {/each}
            <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody>
          {#if pageBlobs.length === 0}
            <tr><td colspan="5" class="px-4 py-10 text-center text-gray-400 text-sm">No blobs found.</td></tr>
          {:else}
            {#each pageBlobs as blob (blob.blobName)}
              <tr class="border-b border-gray-100 hover:bg-blue-50 transition-colors">
                <td class="px-4 py-3">
                  <input type="checkbox" checked={selected.has(blob.blobName)} onchange={() => toggleSelect(blob.blobName)} class="rounded" />
                </td>
                <td class="px-4 py-3">
                  <span class="font-mono text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded">{blob.blobName}</span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-600 whitespace-nowrap">{formatSize(blob.blobSize)}</td>
                <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{formatTs(blob.lastModified)}</td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-1">
                    <button class="p-1.5 rounded text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-colors" onclick={() => viewingBlob = blob} title="View">
                      <i class="fas fa-eye"></i>
                    </button>
                    <button class="p-1.5 rounded text-gray-400 hover:text-green-600 hover:bg-green-50 transition-colors" onclick={() => downloadBlob(blob.blobName)} title="Download">
                      <i class="fas fa-download"></i>
                    </button>
                    <button class="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors" onclick={() => deleteOne(blob.blobName)} title="Delete">
                      <i class="fas fa-trash"></i>
                    </button>
                  </div>
                </td>
              </tr>
            {/each}
          {/if}
        </tbody>
      </table>

      <!-- Pagination -->
      <div class="flex items-center justify-between px-4 py-3 border-t border-gray-200">
        <span class="text-xs text-gray-500">{allBlobs.length} blob(s) · Page {page + 1} of {totalPages}</span>
        <div class="flex gap-1">
          <button class="px-3 py-1 text-xs rounded border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-40" onclick={() => page--} disabled={page === 0}>
            <i class="fas fa-chevron-left"></i>
          </button>
          <button class="px-3 py-1 text-xs rounded border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-40" onclick={() => page++} disabled={page >= totalPages - 1}>
            <i class="fas fa-chevron-right"></i>
          </button>
        </div>
      </div>

      <!-- Footer Actions -->
      <div class="flex items-center gap-3 px-4 py-3 border-t border-gray-200 bg-gray-50">
        <button
          class="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-md text-sm font-medium hover:bg-red-700 transition-colors disabled:opacity-50"
          onclick={deleteSelected}
          disabled={selected.size === 0}
        >
          <i class="fas fa-trash"></i> Delete Selected ({selected.size})
        </button>
        <button
          class="flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-md text-sm font-medium hover:bg-orange-700 transition-colors"
          onclick={clearSpace}
        >
          <i class="fas fa-broom"></i> Clear Space
        </button>
        <button
          class="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 transition-colors ml-auto"
          onclick={() => showUploadModal = true}
        >
          <i class="fas fa-upload"></i> Upload Blob
        </button>
      </div>
    </div>
  {/if}
</div>

{#if showUploadModal}
  <UploadModal
    domain={selectedDomain}
    container={selectedContainer}
    onclose={() => showUploadModal = false}
    onsave={async () => { showUploadModal = false; await fetchBlobs(); }}
  />
{/if}

{#if viewingBlob}
  <ViewModal blobData={viewingBlob} onclose={() => viewingBlob = null} />
{/if}
