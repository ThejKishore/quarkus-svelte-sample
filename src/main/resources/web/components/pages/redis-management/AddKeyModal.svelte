<script>
  import { showToast } from '../../../lib/toastStore.js';
  import * as api from '../../../lib/redisApi.js';

  const { domain, service, onclose, onsave } = $props();

  let keyName = $state('');
  let keyType = $state('STRING');
  let keyValue = $state('');
  let saving = $state(false);

  const keyTypes = ['STRING', 'HASH', 'LIST', 'SET', 'ZSET'];

  async function submit() {
    if (!keyName.trim()) { showToast('Key name is required', 'warning'); return; }
    if (!keyValue.trim()) { showToast('Key value is required', 'warning'); return; }
    try {
      JSON.parse(keyValue);
    } catch {
      showToast('Key value must be valid JSON', 'warning'); return;
    }
    saving = true;
    try {
      await api.addRedisKey(domain, service, { keyName: keyName.trim(), keyType, keyValue: keyValue.trim() });
      showToast(`Key "${keyName.trim()}" added successfully`, 'success');
      onsave();
    } catch (e) {
      showToast(`Failed to add key: ${e.message}`, 'error');
    } finally {
      saving = false;
    }
  }
</script>

<!-- Backdrop -->
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onclick={onclose}>
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden" onclick={e => e.stopPropagation()}>
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
      <div class="flex items-center gap-2">
        <i class="fas fa-plus text-red-500"></i>
        <span class="text-base font-semibold text-gray-800">Add New Redis Key</span>
      </div>
      <button class="text-gray-400 hover:text-gray-600 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Body -->
    <div class="p-6 space-y-4">
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Key Name</span>
        <input
          type="text"
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-500"
          placeholder="e.g. user:session:123"
          bind:value={keyName}
        />
      </div>
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Key Type</span>
        <select
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-500 bg-white"
          bind:value={keyType}
        >
          {#each keyTypes as t}
            <option value={t}>{t}</option>
          {/each}
        </select>
      </div>
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Key Value (JSON)</span>
        <textarea
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-red-500 resize-none"
          rows="6"
          placeholder="{'{'}&quot;example&quot;: &quot;value&quot;{'}'}"
          bind:value={keyValue}
        ></textarea>
      </div>
    </div>

    <!-- Footer -->
    <div class="flex justify-end gap-3 px-6 py-4 border-t border-gray-200">
      <button
        class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors"
        onclick={onclose}
        disabled={saving}
      >Cancel</button>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-md text-sm font-medium hover:bg-red-700 transition-colors disabled:opacity-50"
        onclick={submit}
        disabled={saving}
      >
        <i class="fas fa-save"></i>
        {saving ? 'Saving…' : 'Add Key'}
      </button>
    </div>
  </div>
</div>
