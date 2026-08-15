<script>
  import Toast from '../toast/Toast.svelte';
  import SideMenu from '../side-menu/SideMenu.svelte';
  import GatewayAdminPage from '../pages/gateway-admin/Page.svelte';
  import ConfigServerPage from '../pages/config-server/Page.svelte';
  import RedisManagementPage from '../pages/redis-management/Page.svelte';
  import BlobStoragePage from '../pages/blob-management/Page.svelte';
  import TableStoragePage from '../pages/table-storage-management/Page.svelte';

  let activeView = $state('gateway');
</script>

<div class="flex h-screen overflow-hidden bg-gray-900">
  <SideMenu {activeView} onSelect={id => activeView = id} />

  <div class="flex-1 overflow-hidden flex flex-col">
    {#if activeView === 'gateway'}
      <GatewayAdminPage />
    {:else if activeView === 'config'}
      <ConfigServerPage />
    {:else if activeView === 'redis'}
      <RedisManagementPage />
    {:else if activeView === 'blob'}
      <BlobStoragePage />
    {:else if activeView === 'table-storage'}
      <TableStoragePage />
    {/if}
  </div>
</div>

<Toast />
