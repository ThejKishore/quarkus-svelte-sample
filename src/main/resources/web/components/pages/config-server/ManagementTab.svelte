<script>
  import { onMount } from 'svelte';
  import * as api from '../../../lib/configApi.js';
  import { showToast } from '../../../lib/toastStore.js';

  let domains = $state([]);
  let apps = $state([]);
  let selectedDomain = $state('');
  let selectedApp = $state('');
  let props = $state([]);
  let edits = $state({});
  let sync = $state(null);
  let showContent = $state(false);
  let newKey = $state('');
  let newValue = $state('');

  onMount(loadMeta);

  async function loadMeta() {
    try {
      const meta = await api.getMetadata();
      domains = meta.domains ?? [];
    } catch (e) {
      console.error('loadMeta:', e.message);
    }
  }

  async function onDomainChange() {
    apps = [];
    selectedApp = '';
    showContent = false;
    sync = null;
    props = [];
    if (!selectedDomain) return;
    try {
      const meta = await api.getMetadata();
      apps = meta.applicationsByDomain?.[selectedDomain] ?? [];
    } catch (e) {
      console.error('loadApps:', e.message);
    }
  }

  async function loadProperties() {
    if (!selectedDomain) { showToast('Please select a domain', 'warning'); return; }
    if (!selectedApp)    { showToast('Please select an application', 'warning'); return; }
    try {
      const result = await api.getProperties(selectedApp, selectedDomain);
      props = result.properties ?? [];
      edits = Object.fromEntries(props.map(p => [p.propertyKey, p.propertyValue]));
      sync = result.sync ?? null;
      if (!sync) {
        try { sync = await api.getConfigSyncInfo(selectedApp, selectedDomain); } catch {}
      }
      showContent = true;
    } catch (e) {
      showToast(`Failed to load properties: ${e.message}`, 'error');
    }
  }

  async function publishChanges() {
    if (!selectedDomain || !selectedApp) return;
    try {
      if (!sync) sync = await api.getConfigSyncInfo(selectedApp, selectedDomain);
      await api.updateProperties(selectedApp, selectedDomain, {
        properties: { ...edits },
        expectedVersionNumber: sync.versionNumber,
        expectedUpdatedTm: sync.updatedTm,
        updatedBy: 'admin',
      });
      showToast('Properties published successfully!', 'success');
      await loadProperties();
    } catch (e) {
      showToast(`Failed to publish: ${e.message}`, 'error');
    }
  }

  function resetEdits() {
    edits = Object.fromEntries(props.map(p => [p.propertyKey, p.propertyValue]));
    showToast('Edits reset', 'info');
  }

  async function deleteProperty(key) {
    if (!confirm(`Delete property '${key}'? This cannot be undone.`)) return;
    try {
      await api.deleteProperty(selectedApp, selectedDomain, key);
      showToast(`Property '${key}' deleted`, 'success');
      await loadProperties();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  async function addProperty() {
    if (!selectedDomain) { showToast('Select a domain first', 'warning'); return; }
    if (!selectedApp)    { showToast('Select an application first', 'warning'); return; }
    const k = newKey.trim(); const v = newValue.trim();
    if (!k || !v) { showToast('Key and value are required', 'warning'); return; }
    try {
      await api.addProperty(selectedApp, selectedDomain, { propertyKey: k, propertyValue: v });
      showToast(`Property '${k}' added!`, 'success');
      newKey = ''; newValue = '';
      await loadProperties();
    } catch (e) {
      showToast(`Add failed: ${e.message}`, 'error');
    }
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
        onclick={loadProperties}
      >
        <i class="fas fa-download"></i> Load Properties
      </button>
    </div>
  </div>

  <!-- Sync banner -->
  {#if sync && showContent}
    <div class="bg-indigo-50 border border-indigo-200 rounded-lg px-4 py-3">
      <div class="flex flex-wrap gap-6">
        {#each [['Version', sync.versionNumber], ['Updated By', sync.updatedBy || '—'], ['Updated At', formatTs(sync.updatedTm)]] as [label, value]}
          <div class="flex items-center gap-1.5">
            <span class="text-xs text-indigo-600 font-medium">{label}:</span>
            <span class="text-xs font-bold text-indigo-900">{value}</span>
          </div>
        {/each}
      </div>
    </div>
  {/if}

  <!-- Properties table -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-x-auto">
    <table class="min-w-full">
      <thead class="bg-gray-50 border-b border-gray-200">
        <tr>
          {#each ['Property Key','Value','Updated By','Updated At',''] as h}
            <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider whitespace-nowrap">{h}</th>
          {/each}
        </tr>
      </thead>
      <tbody>
        {#if props.length === 0}
          <tr>
            <td colspan="5" class="px-4 py-10 text-center text-gray-400 text-sm">No properties found.</td>
          </tr>
        {:else}
          {#each props as prop (prop.propertyKey)}
            <tr class="border-b border-gray-100 hover:bg-gray-50">
              <td class="px-4 py-3">
                <span class="font-mono text-xs bg-gray-100 text-gray-800 px-2 py-1 rounded whitespace-nowrap">{prop.propertyKey}</span>
              </td>
              <td class="px-4 py-3 min-w-[200px]">
                <input
                  type="text"
                  class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white"
                  value={edits[prop.propertyKey] ?? prop.propertyValue}
                  oninput={e => edits = { ...edits, [prop.propertyKey]: e.target.value }}
                />
              </td>
              <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{prop.updatedBy || '—'}</td>
              <td class="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{formatTs(prop.updatedTm)}</td>
              <td class="px-4 py-3">
                <button class="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors" onclick={() => deleteProperty(prop.propertyKey)}>
                  <i class="fas fa-trash"></i>
                </button>
              </td>
            </tr>
          {/each}
        {/if}
      </tbody>
    </table>
  </div>

  <!-- Action buttons -->
  {#if showContent}
    <div class="flex justify-end gap-3">
      <button class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={resetEdits}>
        <i class="fas fa-undo"></i> Reset
      </button>
      <button class="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 transition-colors" onclick={publishChanges}>
        <i class="fas fa-cloud-upload-alt"></i> Publish Changes
      </button>
    </div>

    <!-- Add property card -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <span class="block text-sm font-semibold text-gray-700 mb-3">Add New Property</span>
      <div class="flex items-end gap-3 flex-wrap">
        <div class="flex-1 min-w-[200px]">
          <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Property Key</span>
          <input type="text" class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white" placeholder="e.g. spring.datasource.url" bind:value={newKey} />
        </div>
        <div class="flex-1 min-w-[200px]">
          <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Property Value</span>
          <input type="text" class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white" placeholder="Value" bind:value={newValue} />
        </div>
        <button class="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-md text-sm font-medium hover:bg-indigo-700 transition-colors" onclick={addProperty}>
          <i class="fas fa-plus"></i> Add Property
        </button>
      </div>
    </div>
  {/if}
</div>
