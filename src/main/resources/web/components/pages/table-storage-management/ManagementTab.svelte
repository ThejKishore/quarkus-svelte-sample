<script>
  import { onMount } from 'svelte';
  import * as api from '../../../lib/tableStorageApi.js';
  import { showToast } from '../../../lib/toastStore.js';
  import AddTableRecordModal from './AddRecordModal.svelte';
  import ViewTableRecordModal from './ViewRecordModal.svelte';

  const PAGE_SIZE = 10;

  let domains = $state([]);
  let tables = $state([]);
  let selectedDomain = $state('');
  let selectedTable = $state('');

  let allRecords = $state([]);
  let page = $state(0);
  let sortCol = $state('partitionKey');
  let sortDir = $state('asc');
  let selected = $state(new Set());
  let loaded = $state(false);
  let loading = $state(false);

  let showAddModal = $state(false);
  let viewingRecord = $state(null);

  onMount(loadDomains);

  async function loadDomains() {
    try {
      domains = await api.getDomains();
    } catch (e) {
      showToast(`Failed to load domains: ${e.message}`, 'error');
    }
  }

  async function onDomainChange() {
    tables = [];
    selectedTable = '';
    allRecords = [];
    loaded = false;
    if (!selectedDomain) return;
    try {
      tables = await api.getTables(selectedDomain);
    } catch (e) {
      showToast(`Failed to load tables: ${e.message}`, 'error');
    }
  }

  async function fetchRecords() {
    if (!selectedDomain) { showToast('Please select a domain', 'warning'); return; }
    if (!selectedTable)  { showToast('Please select a table', 'warning'); return; }
    loading = true;
    try {
      allRecords = await api.getRecords(selectedDomain, selectedTable);
      loaded = true;
      page = 0;
      selected = new Set();
    } catch (e) {
      showToast(`Failed to fetch records: ${e.message}`, 'error');
    } finally {
      loading = false;
    }
  }

  function setSort(col) {
    if (sortCol === col) { sortDir = sortDir === 'asc' ? 'desc' : 'asc'; }
    else { sortCol = col; sortDir = 'asc'; }
    page = 0;
  }

  let sortedRecords = $derived((() => {
    const arr = [...allRecords];
    arr.sort((a, b) => {
      const av = a[sortCol] ?? ''; const bv = b[sortCol] ?? '';
      return (av < bv ? -1 : av > bv ? 1 : 0) * (sortDir === 'asc' ? 1 : -1);
    });
    return arr;
  })());

  let totalPages = $derived(Math.max(1, Math.ceil(sortedRecords.length / PAGE_SIZE)));
  let pageRecords = $derived(sortedRecords.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE));

  function sortIcon(col) {
    if (sortCol !== col) return 'fas fa-sort text-gray-300';
    return sortDir === 'asc' ? 'fas fa-sort-up text-emerald-500' : 'fas fa-sort-down text-emerald-500';
  }

  function recordKey(r) { return `${r.partitionKey}::${r.rowKey}`; }

  function toggleSelect(r) {
    const s = new Set(selected);
    const k = recordKey(r);
    if (s.has(k)) s.delete(k); else s.add(k);
    selected = s;
  }

  function toggleAll() {
    if (selected.size === pageRecords.length) { selected = new Set(); }
    else { selected = new Set(pageRecords.map(recordKey)); }
  }

  async function deleteSelected() {
    if (selected.size === 0) { showToast('No records selected', 'warning'); return; }
    if (!confirm(`Delete ${selected.size} selected record(s)?`)) return;
    try {
      const records = [...selected].map(k => {
        const [partitionKey, rowKey] = k.split('::');
        return { partitionKey, rowKey };
      });
      await api.deleteRecords(selectedDomain, selectedTable, records);
      showToast(`${selected.size} record(s) deleted`, 'success');
      await fetchRecords();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  async function clearTable() {
    if (!confirm('Delete ALL records in the selected table? This cannot be undone.')) return;
    try {
      await api.clearTable(selectedDomain, selectedTable);
      showToast('Table cleared', 'success');
      await fetchRecords();
    } catch (e) {
      showToast(`Clear failed: ${e.message}`, 'error');
    }
  }

  async function deleteOne(r) {
    if (!confirm(`Delete record (${r.partitionKey} / ${r.rowKey})?`)) return;
    try {
      await api.deleteRecord(selectedDomain, selectedTable, r.partitionKey, r.rowKey);
      showToast('Record deleted', 'success');
      await fetchRecords();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }

  function kvSummary(record) {
    const excluded = new Set(['partitionKey', 'rowKey', 'timestamp']);
    const pairs = Object.entries(record).filter(([k]) => !excluded.has(k));
    if (!pairs.length) return '—';
    return `${pairs.length} pair(s)`;
  }
</script>

<div class="p-4 space-y-4">
  <!-- Section 1: Selectors -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div class="flex items-end gap-3 flex-wrap">
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Domain Name</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white min-w-[160px]"
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
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Table Name</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white min-w-[160px]"
          bind:value={selectedTable}
          disabled={!selectedDomain}
        >
          <option value="">— select table —</option>
          {#each tables as t}
            <option value={t}>{t}</option>
          {/each}
        </select>
      </div>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-md text-sm font-medium hover:bg-emerald-700 transition-colors disabled:opacity-50"
        onclick={fetchRecords}
        disabled={loading}
      >
        <i class="fas fa-search {loading ? 'animate-spin' : ''}"></i>
        {loading ? 'Fetching…' : 'Fetch Table Details'}
      </button>
    </div>
  </div>

  <!-- Section 2: Records Table -->
  {#if loaded}
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-x-auto">
      <table class="min-w-full">
        <thead class="bg-gray-50 border-b border-gray-200">
          <tr>
            <th class="px-4 py-3">
              <input type="checkbox" checked={selected.size === pageRecords.length && pageRecords.length > 0} onchange={toggleAll} class="rounded" />
            </th>
            {#each [['partitionKey','Partition Key'],['rowKey','Row Key'],['timestamp','Timestamp']] as [col, label]}
              <th
                class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider cursor-pointer select-none whitespace-nowrap hover:bg-gray-100"
                onclick={() => setSort(col)}
              >
                {label} <i class="{sortIcon(col)} ml-1 text-xs"></i>
              </th>
            {/each}
            <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Key-Value Pairs</th>
            <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Actions</th>
          </tr>
        </thead>
        <tbody>
          {#if pageRecords.length === 0}
            <tr><td colspan="6" class="px-4 py-10 text-center text-gray-400 text-sm">No records found.</td></tr>
          {:else}
            {#each pageRecords as record (recordKey(record))}
              <tr class="border-b border-gray-100 hover:bg-emerald-50 transition-colors">
                <td class="px-4 py-3">
                  <input type="checkbox" checked={selected.has(recordKey(record))} onchange={() => toggleSelect(record)} class="rounded" />
                </td>
                <td class="px-4 py-3">
                  <span class="font-mono text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded">{record.partitionKey}</span>
                </td>
                <td class="px-4 py-3">
                  <span class="font-mono text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded">{record.rowKey}</span>
                </td>
                <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{formatTs(record.timestamp)}</td>
                <td class="px-4 py-3">
                  <button
                    class="flex items-center gap-1 text-xs text-emerald-600 hover:text-emerald-800 font-medium"
                    onclick={() => viewingRecord = record}
                  >
                    <i class="fas fa-eye"></i> {kvSummary(record)}
                  </button>
                </td>
                <td class="px-4 py-3 whitespace-nowrap">
                  <div class="flex items-center gap-1">
                    <button class="p-1.5 rounded text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-colors" onclick={() => viewingRecord = record} title="View">
                      <i class="fas fa-eye"></i>
                    </button>
                    <button class="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors" onclick={() => deleteOne(record)} title="Delete">
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
        <span class="text-xs text-gray-500">{allRecords.length} record(s) · Page {page + 1} of {totalPages}</span>
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
          onclick={clearTable}
        >
          <i class="fas fa-broom"></i> Clear Space
        </button>
        <button
          class="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-md text-sm font-medium hover:bg-emerald-700 transition-colors ml-auto"
          onclick={() => showAddModal = true}
        >
          <i class="fas fa-plus"></i> Add New Record
        </button>
      </div>
    </div>
  {/if}
</div>

{#if showAddModal}
  <AddRecordModal
    domain={selectedDomain}
    table={selectedTable}
    onclose={() => showAddModal = false}
    onsave={async () => { showAddModal = false; await fetchRecords(); }}
  />
{/if}

{#if viewingRecord}
  <ViewRecordModal record={viewingRecord} onclose={() => viewingRecord = null} />
{/if}
