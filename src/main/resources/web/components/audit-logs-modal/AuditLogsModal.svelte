<script>
  import { onMount } from 'svelte';
  import * as api from '../../lib/gatewayApi.js';
  import { showToast } from '../../lib/toastStore.js';

  const { onclose } = $props();

  let logs = $state([]);
  let status = $state('');

  onMount(loadLogs);

  async function loadLogs() {
    status = 'Loading…';
    logs = await api.getChangeLogs(100);
    status = `${logs.length} entries`;
    if (logs.length > 0) showToast('Audit logs refreshed.', 'success');
  }

  function actionBadgeClass(action) {
    return {
      CREATE_ROUTE:   'bg-green-100 text-green-700',
      UPDATE_ROUTE:   'bg-blue-100 text-blue-700',
      DELETE_ROUTE:   'bg-red-100 text-red-700',
      ENABLE_ROUTE:   'bg-green-100 text-green-700',
      DISABLE_ROUTE:  'bg-yellow-100 text-yellow-700',
      RELOAD_GATEWAY: 'bg-gray-100 text-gray-700',
    }[action] ?? 'bg-gray-100 text-gray-600';
  }

  function formatEpoch(epochSeconds) {
    if (!epochSeconds) return '—';
    return new Date(epochSeconds * 1000).toLocaleString();
  }
</script>

<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-4xl mx-4 flex flex-col overflow-hidden h-[70vh]">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50 flex-shrink-0">
      <div class="flex items-center gap-3">
        <span class="text-lg font-semibold text-gray-800">Audit Logs</span>
        <span class="text-xs text-gray-500">{status}</span>
      </div>
      <button class="p-1.5 text-gray-400 hover:text-gray-600 rounded transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Table -->
    <div class="flex-1 overflow-auto">
      <table class="min-w-full bg-white">
        <thead class="bg-gray-50 sticky top-0 z-10">
          <tr>
            {#each ['Action','Route','Details','Performed By','Time'] as h}
              <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200">{h}</th>
            {/each}
          </tr>
        </thead>
        <tbody>
          {#if logs.length === 0}
            <tr>
              <td colspan="5" class="px-4 py-10 text-center text-gray-400">No audit log entries found.</td>
            </tr>
          {:else}
            {#each logs as log, i (i)}
              <tr class="border-b border-gray-100 hover:bg-gray-50 transition-colors">
                <td class="px-4 py-3">
                  <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {actionBadgeClass(log.action)}">
                    {log.action ?? '—'}
                  </span>
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">{log['route-name'] ?? '—'}</td>
                <td class="px-4 py-3 text-sm text-gray-600">{log.details ?? '—'}</td>
                <td class="px-4 py-3 text-sm text-gray-600 whitespace-nowrap">{log['performed-by'] ?? '—'}</td>
                <td class="px-4 py-3 text-sm text-gray-500 whitespace-nowrap">{formatEpoch(log['created-at'])}</td>
              </tr>
            {/each}
          {/if}
        </tbody>
      </table>
    </div>

    <!-- Footer -->
    <div class="flex justify-end items-center gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50 flex-shrink-0">
      <button class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={loadLogs}>
        <i class="fas fa-sync"></i> Refresh
      </button>
      <button class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i> Close
      </button>
    </div>
  </div>
</div>
