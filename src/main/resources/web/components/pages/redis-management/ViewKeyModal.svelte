<script>
  const { keyData, onclose } = $props();

  function formatJson(val) {
    try { return JSON.stringify(JSON.parse(val), null, 2); } catch { return val; }
  }

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }
</script>

<!-- Backdrop -->
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onclick={onclose}>
  <!-- Modal -->
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-2xl mx-4 overflow-hidden" onclick={e => e.stopPropagation()}>
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
      <div class="flex items-center gap-2">
        <i class="fas fa-key text-red-500"></i>
        <span class="text-base font-semibold text-gray-800">Redis Key Details</span>
      </div>
      <button class="text-gray-400 hover:text-gray-600 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Body -->
    <div class="p-6 space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Key Name</span>
          <span class="font-mono text-sm bg-gray-100 px-2 py-1 rounded block">{keyData.keyName}</span>
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Key Type</span>
          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-700">{keyData.keyType || '—'}</span>
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Last Modified</span>
          <span class="text-sm text-gray-700">{formatTs(keyData.lastModified)}</span>
        </div>
      </div>
      <div>
        <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Key Value (JSON)</span>
        <pre class="bg-gray-900 text-green-400 rounded-lg p-4 text-xs overflow-auto max-h-64 font-mono whitespace-pre-wrap">{formatJson(keyData.keyValue)}</pre>
      </div>
    </div>

    <!-- Footer -->
    <div class="flex justify-end px-6 py-4 border-t border-gray-200">
      <button class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={onclose}>
        Close
      </button>
    </div>
  </div>
</div>
