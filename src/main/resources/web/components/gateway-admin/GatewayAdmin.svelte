<script>
  import { onMount } from 'svelte';
  import * as api from '../../lib/gatewayApi.js';
  import { showToast } from '../../lib/toastStore.js';
  import RouteFormModal from '../route-form-modal/RouteFormModal.svelte';
  import AuditLogsModal from '../audit-logs-modal/AuditLogsModal.svelte';

  let allRoutes = $state([]);
  let displayedRoutes = $state([]);
  let health = $state(null);
  let searchQuery = $state('');

  let stats = $derived({
    total:    allRoutes.length,
    active:   allRoutes.filter(r => r.enabled).length,
    disabled: allRoutes.filter(r => !r.enabled).length,
    health:   health?.status ?? 'UNKNOWN',
  });

  let showRouteModal = $state(false);
  let routeModalMode = $state('create'); // 'create' | 'edit'
  let editingRoute = $state(null);

  let showAuditModal = $state(false);

  onMount(() => { refreshData(); });

  async function refreshData() {
    allRoutes = await api.listRoutes();
    health = await api.getHealth();
    applyFilter(searchQuery);
  }

  function applyFilter(q) {
    searchQuery = q;
    if (!q.trim()) {
      displayedRoutes = allRoutes;
    } else {
      const lower = q.toLowerCase();
      displayedRoutes = allRoutes.filter(r =>
        r.name?.toLowerCase().includes(lower) ||
        r['path-pattern']?.toLowerCase().includes(lower) ||
        r['routing-type']?.toLowerCase().includes(lower)
      );
    }
  }

  async function reloadGateway() {
    try {
      const resp = await api.reloadGateway();
      showToast(`Gateway reloaded — ${resp.routes} route(s) active.`, 'success');
      await refreshData();
    } catch (e) {
      showToast(`Reload failed: ${e.message}`, 'error');
    }
  }

  async function toggleRoute(route) {
    try {
      if (route.enabled) {
        await api.disableRoute(route.id);
        showToast('Route disabled.', 'info');
      } else {
        await api.enableRoute(route.id);
        showToast('Route enabled.', 'success');
      }
      await refreshData();
    } catch (e) {
      showToast(`Toggle failed: ${e.message}`, 'error');
    }
  }

  async function confirmDelete(route) {
    if (!confirm(`Delete route "${route.name}"? This cannot be undone.`)) return;
    try {
      await api.deleteRoute(route.id);
      showToast('Route deleted.', 'success');
      await refreshData();
    } catch (e) {
      showToast(`Delete failed: ${e.message}`, 'error');
    }
  }

  function openCreate() {
    editingRoute = null;
    routeModalMode = 'create';
    showRouteModal = true;
  }

  function openEdit(route) {
    editingRoute = route;
    routeModalMode = 'edit';
    showRouteModal = true;
  }

  function formatTargets(targets) {
    if (!targets?.length) return '—';
    const urls = targets.map(t => t.url).filter(u => u?.trim());
    if (!urls.length) return '—';
    const preview = urls.slice(0, 2).join(', ');
    return urls.length > 2 ? `${preview} (+${urls.length - 2} more)` : preview;
  }

  function shortLb(lb) {
    return { ROUND_ROBIN: 'RR', WEIGHTED: 'W', RANDOM: 'RND' }[lb] ?? (lb || '—');
  }

  function typeBadgeClass(type) {
    return {
      PATH:          'bg-gray-100 text-gray-700',
      REGEX:         'bg-yellow-100 text-yellow-700',
      TRAFFIC_SPLIT: 'bg-green-100 text-green-700',
    }[type] ?? 'bg-gray-100 text-gray-700';
  }
</script>

<div class="flex flex-col h-full bg-gray-50">
  <!-- Stats bar -->
  <div class="grid grid-cols-4 gap-4 p-4 bg-white border-b border-gray-200 flex-shrink-0">
    {#each [
      { label: 'Total Routes', value: stats.total },
      { label: 'Active',       value: stats.active },
      { label: 'Disabled',     value: stats.disabled },
      { label: 'Health',       value: stats.health, colored: true },
    ] as card}
      <div class="bg-gray-50 rounded-lg p-4 border border-gray-200 flex flex-col gap-1">
        <span
          class="text-3xl font-bold text-gray-800"
          style={card.colored ? `color:${stats.health === 'UP' ? '#16a34a' : '#dc2626'}` : ''}
        >{card.value}</span>
        <span class="text-xs font-medium text-gray-500 uppercase tracking-wider">{card.label}</span>
      </div>
    {/each}
  </div>

  <!-- Toolbar -->
  <div class="flex items-center gap-3 px-4 py-3 bg-white border-b border-gray-200 flex-shrink-0">
    <button class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 transition-colors" onclick={openCreate}>
      <i class="fas fa-plus"></i> New Route
    </button>
    <button class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={reloadGateway}>
      <i class="fas fa-sync"></i> Reload Gateway
    </button>
    <button class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={() => showAuditModal = true}>
      <i class="fas fa-list"></i> Audit Logs
    </button>
    <span class="ml-auto text-sm text-gray-500">{displayedRoutes.length} / {allRoutes.length} route(s)</span>
  </div>

  <!-- Search -->
  <div class="px-4 py-3 bg-white border-b border-gray-200 flex-shrink-0">
    <input
      type="text"
      class="w-80 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
      placeholder="Search routes by name, path, or type…"
      value={searchQuery}
      oninput={e => applyFilter(e.target.value)}
    />
  </div>

  <!-- Routes table -->
  <div class="flex-1 overflow-auto">
    <table class="min-w-full bg-white">
      <thead class="bg-gray-50 sticky top-0 z-10">
        <tr>
          {#each ['Name','Path Pattern','Type','Targets','LB','Status','Timeout','Actions'] as h}
            <th class="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200">{h}</th>
          {/each}
        </tr>
      </thead>
      <tbody>
        {#if displayedRoutes.length === 0}
          <tr>
            <td colspan="8" class="px-4 py-10 text-center text-gray-400">
              No routes found. Click "New Route" to add one.
            </td>
          </tr>
        {:else}
          {#each displayedRoutes as route (route.id)}
            <tr class="border-b border-gray-100 hover:bg-blue-50 transition-colors">
              <td class="px-4 py-3 text-sm font-medium text-gray-800 whitespace-nowrap">{route.name || '—'}</td>
              <td class="px-4 py-3">
                <span class="font-mono text-xs bg-gray-100 text-gray-700 px-2 py-1 rounded whitespace-nowrap">
                  {route['path-pattern'] || '—'}
                </span>
              </td>
              <td class="px-4 py-3">
                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {typeBadgeClass(route['routing-type'])}">
                  {route['routing-type'] || '—'}
                </span>
              </td>
              <td class="px-4 py-3 text-sm text-gray-600">{formatTargets(route.targets)}</td>
              <td class="px-4 py-3 text-sm text-gray-500 whitespace-nowrap">{shortLb(route['load-balancer-type'])}</td>
              <td class="px-4 py-3">
                <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold {route.enabled ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}">
                  {route.enabled ? 'ACTIVE' : 'DISABLED'}
                </span>
              </td>
              <td class="px-4 py-3 text-sm text-gray-600 whitespace-nowrap">
                {(route['timeout-ms'] > 0 ? route['timeout-ms'] : 5000)} ms
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <div class="flex items-center gap-1">
                  <button class="p-1.5 rounded text-gray-400 hover:text-blue-600 hover:bg-blue-100 transition-colors" onclick={() => openEdit(route)} title="Edit">
                    <i class="fas fa-pen"></i>
                  </button>
                  <button class="p-1.5 rounded text-gray-400 hover:text-yellow-600 hover:bg-yellow-100 transition-colors" onclick={() => toggleRoute(route)} title={route.enabled ? 'Disable' : 'Enable'}>
                    <i class={route.enabled ? 'fas fa-pause' : 'fas fa-play'}></i>
                  </button>
                  <button class="p-1.5 rounded text-gray-400 hover:text-red-600 hover:bg-red-100 transition-colors" onclick={() => confirmDelete(route)} title="Delete">
                    <i class="fas fa-trash"></i>
                  </button>
                </div>
              </td>
            </tr>
          {/each}
        {/if}
      </tbody>
    </table>
  </div>
</div>

{#if showRouteModal}
  <RouteFormModal
    mode={routeModalMode}
    route={editingRoute}
    onclose={() => showRouteModal = false}
    onsave={async () => { showRouteModal = false; await refreshData(); }}
  />
{/if}

{#if showAuditModal}
  <AuditLogsModal onclose={() => showAuditModal = false} />
{/if}
