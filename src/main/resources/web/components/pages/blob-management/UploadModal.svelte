<script>
  import { showToast } from '../../../lib/toastStore.js';
  import * as api from '../../../lib/blobApi.js';

  const { domain, container, onclose, onsave } = $props();

  let file = $state(null);
  let uploading = $state(false);

  async function submit() {
    if (!file) { showToast('Please select a file to upload', 'warning'); return; }
    uploading = true;
    try {
      await api.uploadBlob(domain, container, file);
      showToast(`"${file.name}" uploaded successfully`, 'success');
      onsave();
    } catch (e) {
      showToast(`Upload failed: ${e.message}`, 'error');
    } finally {
      uploading = false;
    }
  }
</script>

<!-- Backdrop -->
<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onclick={onclose}>
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-md mx-4 overflow-hidden" onclick={e => e.stopPropagation()}>
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50">
      <div class="flex items-center gap-2">
        <i class="fas fa-upload text-blue-500"></i>
        <span class="text-base font-semibold text-gray-800">Upload Blob</span>
      </div>
      <button class="text-gray-400 hover:text-gray-600 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Body -->
    <div class="p-6 space-y-4">
      <div class="text-sm text-gray-600">
        Uploading to container: <span class="font-semibold text-gray-800">{container}</span>
      </div>
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-2 uppercase tracking-wide">Select File</span>
        <label class="flex flex-col items-center justify-center w-full h-32 border-2 border-dashed border-gray-300 rounded-lg cursor-pointer hover:border-blue-400 hover:bg-blue-50 transition-colors">
          {#if file}
            <i class="fas fa-file text-blue-500 text-2xl mb-2"></i>
            <span class="text-sm font-medium text-gray-700">{file.name}</span>
            <span class="text-xs text-gray-500">{(file.size / 1024).toFixed(1)} KB</span>
          {:else}
            <i class="fas fa-cloud-upload-alt text-gray-400 text-2xl mb-2"></i>
            <span class="text-sm text-gray-500">Click to select a file</span>
          {/if}
          <input type="file" class="hidden" onchange={e => file = e.target.files[0] || null} />
        </label>
      </div>
    </div>

    <!-- Footer -->
    <div class="flex justify-end gap-3 px-6 py-4 border-t border-gray-200">
      <button
        class="px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors"
        onclick={onclose}
        disabled={uploading}
      >Cancel</button>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 transition-colors disabled:opacity-50"
        onclick={submit}
        disabled={uploading || !file}
      >
        <i class="fas fa-upload"></i>
        {uploading ? 'Uploading…' : 'Upload'}
      </button>
    </div>
  </div>
</div>
