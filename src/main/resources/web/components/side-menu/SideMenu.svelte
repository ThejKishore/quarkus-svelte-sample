<script>
  const { activeView, onSelect } = $props();

  const navItems = [
    { id: 'gateway',       icon: 'fas fa-route',   label: 'Gateway Admin UI' },
    { id: 'config',        icon: 'fas fa-cogs',    label: 'Config Server UI' },
    { id: 'redis',         icon: 'fas fa-database',label: 'Redis Management' },
    { id: 'blob',          icon: 'fas fa-cloud',   label: 'Blob Storage Management' },
    { id: 'table-storage', icon: 'fas fa-table',   label: 'Table Storage Management' },
  ];
</script>

<nav class="w-60 bg-gray-900 flex flex-col flex-shrink-0 h-full select-none">
  <!-- Header -->
  <div class="px-5 py-4 border-b border-gray-700 flex-shrink-0">
    <div class="flex items-center gap-2 mb-0.5">
      <i class="fas fa-bolt text-yellow-400"></i>
      <span class="text-white text-base font-bold tracking-tight">Platform</span>
    </div>
    <span class="text-gray-400 text-xs mt-0.5 block">Admin Console</span>
  </div>

  <!-- Nav items -->
  <div class="flex-1 overflow-y-auto py-3 px-2">
    <span class="block px-3 py-1 text-gray-500 uppercase mb-1 text-xs font-semibold tracking-widest">Main</span>
    {#each navItems as item}
      <button
        class={activeView === item.id
          ? 'flex items-center gap-3 px-3 py-2.5 rounded-lg bg-blue-600 text-white cursor-pointer mb-0.5 w-full text-left'
          : 'flex items-center gap-3 px-3 py-2.5 rounded-lg text-gray-300 hover:bg-gray-700 hover:text-white cursor-pointer transition-colors mb-0.5 w-full text-left'}
        onclick={() => onSelect(item.id)}
      >
        <i class="{item.icon} w-4 text-center text-sm"></i>
        <span class="text-sm font-medium leading-none">{item.label}</span>
      </button>
    {/each}
  </div>

  <!-- Footer -->
  <div class="px-4 py-3 border-t border-gray-700 flex-shrink-0">
    <span class="text-gray-500 text-xs">Gateway UI v1.0.0</span>
  </div>
</nav>
