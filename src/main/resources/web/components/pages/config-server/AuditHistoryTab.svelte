<script>
  import { onMount } from 'svelte';
  import * as api from '../../../lib/configApi.js';
  import { showToast } from '../../../lib/toastStore.js';

  let domains = $state([]);
  let apps = $state([]);
  let selectedDomain = $state('');
  let selectedApp = $state('');
  let records = $state([]);

  onMount(loadMeta);

  async function loadMeta() {
    try {
      const meta = await api.getMetadata();
      domains = meta.domains ?? [];
    } catch (e) {
      console.error('AuditHistoryTab.loadMeta:', e.message);
    }
  }

  async function onDomainChange() {
    apps = [];
    selectedApp = '';
    if (!selectedDomain) return;
    try {
      const meta = await api.getMetadata();
      apps = meta.applicationsByDomain?.[selectedDomain] ?? [];
    } catch (e) {
      console.error('AuditHistoryTab.loadApps:', e.message);
    }
  }

  async function loadHistory() {
    if (!selectedDomain) { showToast('Please select a domain', 'warning'); return; }
    if (!selectedApp)    { showToast('Please select an application', 'warning'); return; }
    try {
      records = await api.getAuditHistory(selectedApp, selectedDomain);
      if (records.length === 0) showToast(`No audit history found for ${selectedApp} / ${selectedDomain}`, 'info');
    } catch (e) {
      showToast(`Failed to load audit history: ${e.message}`, 'error');
    }
  }

  function opBadgeClass(op) {
    return {
      ADDED:    'bg-green-100 text-green-700',
      MODIFIED: 'bg-blue-100 text-blue-700',
      DELETED:  'bg-red-100 text-red-700',
    }[op?.toUpperCase()] ?? 'bg-gray-100 text-gray-700';
  }

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }
</script>

<div class="p-4 space-y-4">
  <!-- Domain / App selector -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div class="flex items-end gap-3 flex-wrap">
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Domain</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white min-w-[160px]"
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
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Application</span>
        <select
          class="border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white min-w-[160px]"
          bind:value={selectedApp}
        >
          <option value="">— select app —</option>
          {#each apps as a}
            <option value={a}>{a}</option>
          {/each}
        </select>
      </div>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-md text-sm font-medium hover:bg-indigo-700 transition-colors"
        onclick={loadHistory}
      >
        <i class="fas fa-history"></i> Load History
      </button>
    </div>
  </div>

  <!-- Audit table -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-x-auto">
    <table class="min-w-full">
      <thead class="bg-gray-50 border-b border-gray-200">
        <tr>
          {#each ['Version','Property Key','Operation','Old Value','New Value','Updated By','Updated At'] as h}
            <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider whitespace-nowrap">{h}</th>
          {/each}
        </tr>
      </thead>
      <tbody>
        {#if records.length === 0}
          <tr>
            <td colspan="7" class="px-4 py-10 text-center text-gray-400 text-sm">No audit records found.</td>
          </tr>
        {:else}
          {#each records as rec, i (i)}
            <tr class="border-b border-gray-100 hover:bg-gray-50">
              <td class="px-4 py-3 text-xs font-mono text-gray-600">{rec.versionNumber}</td>
              <td class="px-4 py-3">
                <span class="font-mono text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded whitespace-nowrap">{rec.propertyKey}</span>
              </td>
              <td class="px-4 py-3">
                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold {opBadgeClass(rec.operation)}">{rec.operation}</span>
              </td>
              <td class="px-4 py-3">
                <span class="font-mono text-xs bg-gray-50 text-gray-500 px-2 py-0.5 rounded">{rec.oldPropertyValue ?? '—'}</span>
              </td>
              <td class="px-4 py-3">
                <span class="font-mono text-xs bg-gray-50 text-gray-700 px-2 py-0.5 rounded">{rec.newPropertyValue ?? '—'}</span>
              </td>
              <td class="px-4 py-3 text-xs text-gray-500">{rec.updatedBy || '—'}</td>
              <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{formatTs(rec.updatedTm)}</td>
            </tr>
          {/each}
        {/if}
      </tbody>
    </table>
  </div>
</div>
