<script>
  const { blobData, onclose } = $props();

  function formatSize(bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  }

  function formatTs(ts) {
    if (!ts) return '—';
    try { return ts.replace('T', ' ').split('.')[0]; } catch { return ts; }
  }
</script>

<!-- Backdrop -->
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onclick={onclose}>
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4 overflow-hidden" onclick={e => e.stopPropagation()}>
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
      <div class="flex items-center gap-2">
        <i class="fas fa-file text-blue-500"></i>
        <span class="text-base font-semibold text-gray-800">Blob Details</span>
      </div>
      <button class="text-gray-400 hover:text-gray-600 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Body -->
    <div class="p-6 space-y-4">
      <div class="grid grid-cols-2 gap-4">
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Blob Name</span>
          <span class="font-mono text-sm bg-gray-100 px-2 py-1 rounded block break-all">{blobData.blobName}</span>
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Blob Size</span>
          <span class="text-sm text-gray-700">{formatSize(blobData.blobSize)}</span>
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Content Type</span>
          <span class="text-sm text-gray-700">{blobData.contentType || '—'}</span>
        </div>
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Last Modified</span>
          <span class="text-sm text-gray-700">{formatTs(blobData.lastModified)}</span>
        </div>
      </div>
      {#if blobData.metadata}
        <div>
          <span class="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Metadata</span>
          <pre class="bg-gray-900 text-green-400 rounded-lg p-3 text-xs overflow-auto max-h-40 font-mono">{JSON.stringify(blobData.metadata, null, 2)}</pre>
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
