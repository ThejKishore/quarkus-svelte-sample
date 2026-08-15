<script>
  import { onMount } from 'svelte';
  import * as api from '../../../lib/redisApi.js';
  import { showToast } from '../../../lib/toastStore.js';
  import AddKeyModal from './AddKeyModal.svelte';
  import ViewKeyModal from './ViewKeyModal.svelte';

  const PAGE_SIZE = 10;

  let domains = $state([]);
  let services = $state([]);
  let selectedDomain = $state('');
  let selectedService = $state('');

  let allKeys = $state([]);
  let page = $state(0);
  let sortCol = $state('keyName');
  let sortDir = $state('asc');
  let selected = $state(new Set());
  let loaded = $state(false);
  let loading = $state(false);

  let showAddModal = $state(false);
  let viewingKey = $state(null);

  onMount(loadDomains);

  async function loadDomains() {
    try {
      domains = await api.getDomains();
    } catch (e) {
      showToast(`Failed to load domains: ${e.message}`, 'error');
    }
  }

  async function onDomainChange() {
    services = [];
    selectedService = '';
    allKeys = [];
    loaded = false;
    if (!selectedDomain) return;
    try {
      services = await api.getServices(selectedDomain);
    } catch (e) {
      showToast(`Failed to load services: ${e.message}`, 'error');
    }
  }

  async function fetchKeys() {
    if (!selectedDomain) { showToast('Please select a domain', 'warning'); return; }
    if (!selectedService) { showToast('Please select a service', 'warning'); return; }
    loading = true;
    try {
      allKeys = await api.getRedisKeys(selectedDomain, selectedService);
      loaded = true;
      page = 0;
      selected = new Set();
    } catch (e) {
      showToast(`Failed to fetch keys: ${e.message}`, 'error');
    } finally {
      loading = false;
    }
  }

  function setSort(col) {
    if (sortCol === col) { sortDir = sortDir === 'asc' ? 'desc' : 'asc'; }
    else { sortCol = col; sortDir = 'asc'; }
    page = 0;
  }

  let sortedKeys = $derived((() => {
    const arr = [...allKeys];
    arr.sort((a, b) => {
      const av = a[sortCol] ?? ''; const bv = b[sortCol] ?? '';
      return (av < bv ? -1 : av > bv ? 1 : 0) * (sortDir === 'asc' ? 1 : -1);
    });
    return arr;
  })());

  let totalPages = $derived(Math.max(1, Math.ceil(sortedKeys.length / PAGE_SIZE)));
  let pageKeys = $derived(sortedKeys.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE));

  function sortIcon(col) {
    if (sortCol !== col) return 'fas fa-sort text-gray-300';
    return sortDir === 'asc' ? 'fas fa-sort-up text-red-500' : 'fas fa-sort-down text-red-500';
  }

  function toggleSelect(keyName) {
    const s = new Set(selected);
    if (s.has(keyName)) s.delete(keyName); else s.add(keyName);
    selected = s;
  }

  function toggleAll() {
    if (selected.size === pageKeys.length) { selected = new Set(); }
    else { selected = new Set(pageKeys.map(k => k.keyName)); }
  }

  async function deleteSelected() {
    if (selected.size === 0) { showToast('No keys selected', 'warning'); return; }
    if (!confirm(`Delete ${selected.size} selected key(s)?`)) return;
    try {
      await api.deleteRedisKeys(selectedDomain, selectedService, [...selected]);
      showToast(`${selected.size} key(s) deleted`, 'success');
      await fetchKeys();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  async function clearAll() {
    if (!confirm('Delete ALL keys for the selected domain and service? This cannot be undone.')) return;
    try {
      await api.clearAllRedisKeys(selectedDomain, selectedService);
      showToast('All keys cleared', 'success');
      await fetchKeys();
    } catch (e) {
      showToast(`Clear failed: ${e.message}`, 'error');
    }
  }

  async function deleteOne(keyName) {
    if (!confirm(`Delete key "${keyName}"?`)) return;
    try {
      await api.deleteRedisKey(selectedDomain, selectedService, keyName);
      showToast(`Key "${keyName}" deleted`, 'success');
      await fetchKeys();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }

  function truncate(str, n = 60) {
    if (!str) return '—';
    return str.length > n ? str.slice(0, n) + '…' : str;
  }
</script>

<div class="p-4 space-y-4">
  <!-- Section 1: Selectors -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div class="flex items-end gap-3 flex-wrap">
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Domain Name</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-500 bg-white min-w-[160px]"
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
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Service Name</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-500 bg-white min-w-[160px]"
          bind:value={selectedService}
          disabled={!selectedDomain}
        >
          <option value="">— select service —</option>
          {#each services as s}
            <option value={s}>{s}</option>
          {/each}
        </select>
      </div>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-md text-sm font-medium hover:bg-red-700 transition-colors disabled:opacity-50"
        onclick={fetchKeys}
        disabled={loading}
      >
        <i class="fas fa-search {loading ? 'animate-spin' : ''}"></i>
        {loading ? 'Fetching…' : 'Fetch Redis Keys'}
      </button>
    </div>
  </div>

  <!-- Section 2: Keys Table -->
  {#if loaded}
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-x-auto">
      <table class="min-w-full">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr>
            <th class="px-4 py-3">
              <input type="checkbox" checked={selected.size === pageKeys.length && pageKeys.length > 0} onchange={toggleAll} class="rounded" />
            </th>
            {#each [['keyName','Key Name'],['keyType','Key Type'],['keyValue','Key Value'],['lastModified','Last Modified']] as [col, label]}
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
          {#if pageKeys.length === 0}
            <tr><td colspan="6" class="px-4 py-10 text-center text-gray-400 text-sm">No keys found.</td></tr>
          {:else}
            {#each pageKeys as key (key.keyName)}
              <tr class="border-b border-gray-100 hover:bg-red-50 transition-colors">
                <td class="px-4 py-3">
                  <input type="checkbox" checked={selected.has(key.keyName)} onchange={() => toggleSelect(key.keyName)} class="rounded" />
                </td>
                <td class="px-4 py-3">
                  <span class="font-mono text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded whitespace-nowrap">{key.keyName}</span>
                </td>
                <td class="px-4 py-3">
                  <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-700">{key.keyType || '—'}</span>
                </td>
                <td class="px-4 py-3 text-xs text-gray-600 max-w-xs truncate">{truncate(key.keyValue)}</td>
                <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{formatTs(key.lastModified)}</td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-1">
                    <button class="p-1.5 rounded text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-colors" onclick={() => viewingKey = key} title="View">
                      <i class="fas fa-eye"></i>
                    </button>
                    <button class="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors" onclick={() => deleteOne(key.keyName)} title="Delete">
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
        <span class="text-xs text-gray-500">{allKeys.length} key(s) · Page {page + 1} of {totalPages}</span>
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
          onclick={clearAll}
        >
          <i class="fas fa-broom"></i> Clear All
        </button>
        <button
          class="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 transition-colors ml-auto"
          onclick={() => showAddModal = true}
        >
          <i class="fas fa-plus"></i> Add New Redis Key
        </button>
      </div>
    </div>
  {/if}
</div>

{#if showAddModal}
  <AddKeyModal
    domain={selectedDomain}
    service={selectedService}
    onclose={() => showAddModal = false}
    onsave={async () => { showAddModal = false; await fetchKeys(); }}
  />
{/if}

{#if viewingKey}
  <ViewKeyModal keyData={viewingKey} onclose={() => viewingKey = null} />
{/if}
