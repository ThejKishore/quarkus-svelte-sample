<script>
  import { onMount } from 'svelte';
  import * as api from '../../../lib/blobApi.js';
  import { showToast } from '../../../lib/toastStore.js';

  const PAGE_SIZE = 10;

  let logs = $state([]);
  let page = $state(0);
  let total = $state(0);
  let loading = $state(false);

  let sortCol = $state('timestamp');
  let sortDir = $state('desc');
  let viewingLog = $state(null);

  onMount(() => loadLogs());

  async function loadLogs() {
    loading = true;
    try {
      const result = await api.getAuditLogs(page, PAGE_SIZE);
      logs = result?.content ?? result ?? [];
      total = result?.totalElements ?? logs.length;
    } catch (e) {
      showToast(`Failed to load audit logs: ${e.message}`, 'error');
    } finally {
      loading = false;
    }
  }

  function setSort(col) {
    if (sortCol === col) { sortDir = sortDir === 'asc' ? 'desc' : 'asc'; }
    else { sortCol = col; sortDir = 'asc'; }
  }

  let sortedLogs = $derived((() => {
    const arr = [...logs];
    arr.sort((a, b) => {
      const av = a[sortCol] ?? ''; const bv = b[sortCol] ?? '';
      return (av < bv ? -1 : av > bv ? 1 : 0) * (sortDir === 'asc' ? 1 : -1);
    });
    return arr;
  })());

  function sortIcon(col) {
    if (sortCol !== col) return 'fas fa-sort text-gray-300';
    return sortDir === 'asc' ? 'fas fa-sort-up text-blue-500' : 'fas fa-sort-down text-blue-500';
  }

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }

  const totalPages = $derived(Math.max(1, Math.ceil(total / PAGE_SIZE)));

  async function goPage(p) {
    page = p;
    await loadLogs();
  }
</script>

<div class="p-4 space-y-4">
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-x-auto">
    <div class="flex items-center justify-between px-4 py-3 border-b border-gray-200">
      <span class="text-sm font-semibold text-gray-700">Blob Audit Logs</span>
      <button
        class="flex items-center gap-2 px-3 py-1.5 bg-gray-100 text-gray-600 rounded-md text-xs font-medium hover:bg-gray-200 transition-colors"
        onclick={loadLogs}
      >
        <i class="fas fa-sync {loading ? 'animate-spin' : ''}"></i> Refresh
      </button>
    </div>

    <table class="min-w-full">
      <thead class="bg-gray-50 border-b border-gray-200">
        <tr>
          {#each [
            ['logId', 'Log ID'],
            ['actionPerformed', 'Action Performed'],
            ['user', 'User'],
            ['timestamp', 'Timestamp'],
          ] as [col, label]}
            <th
              class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider cursor-pointer select-none whitespace-nowrap hover:bg-gray-100"
              onclick={() => setSort(col)}
            >
              {label} <i class="{sortIcon(col)} ml-1 text-xs"></i>
            </th>
          {/each}
          <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Details</th>
        </tr>
      </thead>
      <tbody>
        {#if loading}
          <tr><td colspan="5" class="px-4 py-10 text-center text-gray-400 text-sm"><i class="fas fa-spinner animate-spin mr-2"></i>Loading…</td></tr>
        {:else if sortedLogs.length === 0}
          <tr><td colspan="5" class="px-4 py-10 text-center text-gray-400 text-sm">No audit logs found.</td></tr>
        {:else}
          {#each sortedLogs as log (log.logId)}
            <tr class="border-b border-gray-100 hover:bg-gray-50">
              <td class="px-4 py-3 text-xs font-mono text-gray-600">{log.logId || '—'}</td>
              <td class="px-4 py-3 text-sm text-gray-800">{log.actionPerformed || '—'}</td>
              <td class="px-4 py-3 text-sm text-gray-600">{log.user || '—'}</td>
              <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{formatTs(log.timestamp)}</td>
              <td class="px-4 py-3">
                <button
                  class="p-1.5 rounded text-gray-400 hover:text-blue-600 hover:bg-blue-50 transition-colors"
                  onclick={() => viewingLog = log}
                  title="View Details"
                >
                  <i class="fas fa-eye"></i>
                </button>
              </td>
            </tr>
          {/each}
        {/if}
      </tbody>
    </table>

    <!-- Pagination -->
    <div class="flex items-center justify-between px-4 py-3 border-t border-gray-200">
      <span class="text-xs text-gray-500">Page {page + 1} of {totalPages}</span>
      <div class="flex gap-1">
        <button
          class="px-3 py-1 text-xs rounded border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-40 transition-colors"
          onclick={() => goPage(page - 1)}
          disabled={page === 0}
        ><i class="fas fa-chevron-left"></i></button>
        <button
          class="px-3 py-1 text-xs rounded border border-gray-300 text-gray-600 hover:bg-gray-100 disabled:opacity-40 transition-colors"
          onclick={() => goPage(page + 1)}
          disabled={page >= totalPages - 1}
        ><i class="fas fa-chevron-right"></i></button>
      </div>
    </div>
  </div>
</div>

{#if viewingLog}
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onclick={() => viewingLog = null}>
    <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden" onclick={e => e.stopPropagation()}>
      <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
        <span class="text-base font-semibold text-gray-800">Audit Log Details</span>
        <button class="text-gray-400 hover:text-gray-600" onclick={() => viewingLog = null}><i class="fas fa-times"></i></button>
      </div>
      <div class="p-6">
        <pre class="bg-gray-900 text-green-400 rounded-lg p-4 text-xs overflow-auto max-h-72 font-mono whitespace-pre-wrap">{JSON.stringify(viewingLog, null, 2)}</pre>
      </div>
      <div class="flex justify-end px-6 py-4 border-t border-gray-200">
        <button class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={() => viewingLog = null}>Close</button>
      </div>
    </div>
  </div>
{/if}
