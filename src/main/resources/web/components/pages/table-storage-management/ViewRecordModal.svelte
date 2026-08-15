<script>
  const { record, onclose } = $props();

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }

  let kvPairs = $derived((() => {
    const excluded = new Set(['partitionKey', 'rowKey', 'timestamp']);
    return Object.entries(record).filter(([k]) => !excluded.has(k));
  })());
</script>

<!-- Backdrop -->
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onclick={onclose}>
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden" onclick={e => e.stopPropagation()}>
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
      <div class="flex items-center gap-2">
        <i class="fas fa-table text-emerald-500"></i>
        <span class="text-base font-semibold text-gray-800">Record Details</span>
      </div>
      <button class="text-gray-400 hover:text-gray-600 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Body -->
    <div class="p-6 space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Partition Key</span>
          <span class="font-mono text-sm bg-gray-100 px-2 py-1 rounded block">{record.partitionKey}</span>
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Row Key</span>
          <span class="font-mono text-sm bg-gray-100 px-2 py-1 rounded block">{record.rowKey}</span>
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Timestamp</span>
          <span class="text-sm text-gray-700">{formatTs(record.timestamp)}</span>
        </div>
      </div>

      {#if kvPairs.length > 0}
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Key-Value Pairs</span>
          <div class="border border-gray-200 rounded-lg overflow-hidden">
            <table class="min-w-full">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Key</th>
                  <th class="px-3 py-2 text-left text-xs font-semibold text-gray-500 uppercase">Value</th>
                </tr>
              </thead>
              <tbody>
                {#each kvPairs as [k, v]}
                  <tr class="border-t border-gray-100">
                    <td class="px-3 py-2 text-xs font-mono text-gray-700">{k}</td>
                    <td class="px-3 py-2 text-xs text-gray-600 break-all">{String(v)}</td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        </div>
      {/if}
    </div>

    <!-- Footer -->
    <div class="flex justify-end px-6 py-4 border-t border-gray-200">
      <button class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={onclose}>
        Close
      </button>
    </div>
  </div>
</div>
