<script>
  import ManagementTab from './ManagementTab.svelte';
  import AuditLogsTab from './AuditLogsTab.svelte';

  const tabs = [
    { icon: 'fas fa-key',     label: 'Redis Management', component: ManagementTab },
    { icon: 'fas fa-history', label: 'Redis Audit Logs', component: AuditLogsTab },
  ];

  let activeTab = $state(0);
</script>

<div class="flex flex-col h-full bg-gray-50">
  <!-- Header -->
  <div class="flex items-center gap-3 px-6 py-4 bg-white border-b border-gray-200 flex-shrink-0">
    <i class="fas fa-database text-red-500 text-xl"></i>
    <span class="text-lg font-semibold text-gray-800">Redis Management</span>
  </div>

  <!-- Tab bar -->
  <div class="flex border-b border-gray-200 bg-white px-4 flex-shrink-0">
    {#each tabs as tab, i}
      <button
        class={activeTab === i
          ? 'flex items-center px-4 py-3 text-sm font-medium border-b-2 border-red-600 text-red-600 cursor-pointer whitespace-nowrap'
          : 'flex items-center px-4 py-3 text-sm font-medium border-b-2 border-transparent text-gray-500 hover:text-gray-700 cursor-pointer whitespace-nowrap transition-colors'}
        onclick={() => activeTab = i}
      >
        <i class="{tab.icon} mr-2 text-xs"></i>
        {tab.label}
      </button>
    {/each}
  </div>

  <!-- Content -->
  <div class="flex-1 overflow-auto">
    {#each tabs as tab, i}
      {#if activeTab === i}
        <tab.component />
      {/if}
    {/each}
  </div>
</div>
