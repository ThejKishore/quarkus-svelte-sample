<script>
  import * as api from '../../lib/configApi.js';
  import { showToast } from '../../lib/toastStore.js';

  let domain = $state('');
  let appName = $state('');
  let selectedFile = $state(null);
  let fileLabel = $state('Drop your config file here or click to browse');
  let fileLabelColored = $state(false);

  function triggerFileSelect() {
    const fi = document.createElement('input');
    fi.type = 'file';
    fi.accept = '.properties,.yaml,.yml,.json';
    fi.style.display = 'none';
    document.body.appendChild(fi);
    fi.onchange = () => {
      const file = fi.files?.[0];
      if (file) {
        selectedFile = file;
        fileLabel = `📎 ${file.name}`;
        fileLabelColored = true;
      }
      document.body.removeChild(fi);
    };
    fi.click();
  }

  async function onboard() {
    if (!domain.trim()) { showToast('Domain is required', 'warning'); return; }
    if (!appName.trim()) { showToast('Application name is required', 'warning'); return; }
    if (!selectedFile) { showToast('Please select a configuration file', 'warning'); return; }
    try {
      await api.onboardService(domain.trim(), appName.trim(), selectedFile);
      showToast(`Service '${appName}' onboarded in domain '${domain}'!`, 'success');
      resetForm();
    } catch (e) {
      showToast(e.message || 'Onboarding failed', 'error');
    }
  }

  function resetForm() {
    domain = '';
    appName = '';
    selectedFile = null;
    fileLabel = 'Drop your config file here or click to browse';
    fileLabelColored = false;
  }

  const bullets = [
    'Your configuration file is validated',
    'System checks for duplicate domain + application combinations',
    'Configuration is stored securely in the database',
    'Service becomes available in Configuration Management',
    'You can immediately manage properties via the Config Management screen',
  ];
</script>

<div class="p-4 space-y-4">
  <!-- Info header -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <h2 class="text-xl font-bold text-gray-800 mb-1 mt-0">Service Onboarding</h2>
    <span class="text-sm text-gray-500">
      Onboard a new service by providing domain and application details along with a configuration file.
    </span>
  </div>

  <!-- Form -->
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
    <div class="grid grid-cols-1 gap-4 mb-4 sm:grid-cols-2">
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Domain *</span>
        <input
          type="text"
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white"
          placeholder="e.g. production, staging, development"
          bind:value={domain}
        />
        <span class="text-xs text-gray-400 mt-1 block">Domain where the service will be configured</span>
      </div>
      <div>
        <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Application Name *</span>
        <input
          type="text"
          class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white"
          placeholder="e.g. user-service, api-gateway"
          bind:value={appName}
        />
        <span class="text-xs text-gray-400 mt-1 block">Unique application identifier</span>
      </div>
    </div>

    <span class="block text-xs font-semibold text-gray-600 mb-1 uppercase tracking-wide">Configuration File *</span>
    <div
      class="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-indigo-400 transition-colors mt-1 mb-4"
    >
      <i class="fas fa-cloud-upload-alt text-gray-300 text-4xl mb-3 block"></i>
      <span
        class="block text-sm mb-3"
        style={fileLabelColored ? 'color:#4338CA' : 'color:#9ca3af'}
      >{fileLabel}</span>
      <button
        class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors mx-auto"
        onclick={triggerFileSelect}
      >
        <i class="fas fa-folder-open"></i> Browse Files…
      </button>
      <span class="text-xs text-gray-400 mt-3 block">Accepted: .properties  .yaml  .yml  .json</span>
    </div>

    <div class="flex justify-end gap-3">
      <button class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={resetForm}>
        <i class="fas fa-undo"></i> Reset
      </button>
      <button class="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 transition-colors" onclick={onboard}>
        <i class="fas fa-rocket"></i> Onboard Service
      </button>
    </div>
  </div>

  <!-- Info bullets -->
  <div class="bg-indigo-50 border border-indigo-200 rounded-lg p-4">
    <span class="block text-sm font-semibold text-indigo-700 mb-3">What happens during onboarding?</span>
    {#each bullets as bullet}
      <div class="flex items-start gap-2 mb-1.5">
        <i class="fas fa-check-circle text-indigo-400 text-xs mt-0.5 flex-shrink-0"></i>
        <span class="text-sm text-indigo-700">{bullet}</span>
      </div>
    {/each}
  </div>
</div>
