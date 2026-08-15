<script>
  import { showToast } from '../../../lib/toastStore.js';
  import * as api from '../../../lib/tableStorageApi.js';

  const { domain, table, onclose, onsave } = $props();

  let partitionKey = $state('');
  let rowKey = $state('');
  let kvPairs = $state([{ key: '', value: '' }]);
  let saving = $state(false);

  function addPair() {
    kvPairs = [...kvPairs, { key: '', value: '' }];
  }

  function removePair(i) {
    kvPairs = kvPairs.filter((_, idx) => idx !== i);
  }

  function updatePair(i, field, val) {
    kvPairs = kvPairs.map((p, idx) => idx === i ? { ...p, [field]: val } : p);
  }

  async function submit() {
    if (!partitionKey.trim()) { showToast('Partition Key is required', 'warning'); return; }
    if (!rowKey.trim())       { showToast('Row Key is required', 'warning'); return; }
    const properties = {};
    for (const { key, value } of kvPairs) {
      if (key.trim()) properties[key.trim()] = value;
    }
    saving = true;
    try {
      await api.addRecord(domain, table, {
        partitionKey: partitionKey.trim(),
        rowKey: rowKey.trim(),
        ...properties,
      });
      showToast('Record added successfully', 'success');
      onsave();
    } catch (e) {
      showToast(`Failed to add record: ${e.message}`, 'error');
    } finally {
      saving = false;
    }
  }
</script>

<!-- Backdrop -->
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onclick={onclose}>
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden max-h-[90vh] flex flex-col" onclick={e => e.stopPropagation()}>
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50 flex-shrink-0">
      <div class="flex items-center gap-2">
        <i class="fas fa-plus text-emerald-500"></i>
        <span class="text-base font-semibold text-gray-800">Add New Record</span>
      </div>
      <button class="text-gray-400 hover:text-gray-600 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Body -->
    <div class="p-6 space-y-4 overflow-y-auto flex-1">
      <div class="grid grid-cols-2 gap-4">
        <div>
          <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Partition Key</span>
          <input
            type="text"
            class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
            placeholder="e.g. us-east"
            bind:value={partitionKey}
          />
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Row Key</span>
          <input
            type="text"
            class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
            placeholder="e.g. row-001"
            bind:value={rowKey}
          />
        </div>
      </div>

      <!-- Key-Value Pairs -->
      <div>
        <div class="flex items-center justify-between mb-2">
          <span class="text-xs font-semibold text-gray-600 uppercase tracking-wide">Key-Value Pairs</span>
          <button
            class="flex items-center gap-1 text-xs text-emerald-600 hover:text-emerald-800 font-medium"
            onclick={addPair}
          >
            <i class="fas fa-plus"></i> Add Pair
          </button>
        </div>
        <div class="space-y-2">
          {#each kvPairs as pair, i}
            <div class="flex items-center gap-2">
              <input
                type="text"
                class="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                placeholder="Key"
                value={pair.key}
                oninput={e => updatePair(i, 'key', e.target.value)}
              />
              <input
                type="text"
                class="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                placeholder="Value"
                value={pair.value}
                oninput={e => updatePair(i, 'value', e.target.value)}
              />
              <button
                class="p-2 rounded text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                onclick={() => removePair(i)}
                disabled={kvPairs.length === 1}
              >
                <i class="fas fa-minus"></i>
              </button>
            </div>
          {/each}
        </div>
      </div>
    </div>

    <!-- Footer -->
    <div class="flex justify-end gap-3 px-6 py-4 border-t border-gray-200 flex-shrink-0">
      <button
        class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors"
        onclick={onclose}
        disabled={saving}
      >Cancel</button>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-md text-sm font-medium hover:bg-emerald-700 transition-colors disabled:opacity-50"
        onclick={submit}
        disabled={saving}
      >
        <i class="fas fa-save"></i>
        {saving ? 'Saving…' : 'Submit'}
      </button>
    </div>
  </div>
</div>
