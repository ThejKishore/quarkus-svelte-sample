<script>
  import Toast from '../toast/Toast.svelte';
  import SideMenu from '../side-menu/SideMenu.svelte';
  import GatewayAdmin from '../gateway-admin/GatewayAdmin.svelte';
  import ConfigServer from '../config-server/ConfigServer.svelte';

  let activeView = $state('gateway');
</script>

<div class="flex h-screen overflow-hidden bg-gray-900">
  <SideMenu {activeView} onSelect={id => activeView = id} />

  <div class="flex-1 overflow-hidden flex flex-col">
    {#if activeView === 'gateway'}
      <GatewayAdmin />
    {:else if activeView === 'config'}
      <ConfigServer />
    {/if}
  </div>
</div>

<Toast />
