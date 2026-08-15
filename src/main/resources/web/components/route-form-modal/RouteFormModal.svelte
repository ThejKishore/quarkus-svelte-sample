<script>
  import * as api from '../../lib/gatewayApi.js';
  import { showToast } from '../../lib/toastStore.js';

  const { mode = 'create', route = null, onclose, onsave } = $props();

  // ── Routing type → allowed LB options ──────────────────────────────────────
  const ROUTING_LB_OPTIONS = {
    PATH:          [['ROUND_ROBIN','Round Robin'],['RANDOM','Random']],
    REGEX:         [['ROUND_ROBIN','Round Robin'],['RANDOM','Random']],
    TRAFFIC_SPLIT: [['WEIGHTED','Weighted'],['HEADER','Header-Based']],
  };

  // ── Form state ─────────────────────────────────────────────────────────────
  let activeTab = $state(0);

  // Basic
  let name         = $state('');
  let pathPattern  = $state('');
  let routingType  = $state('PATH');
  let lbType       = $state('ROUND_ROBIN');
  let stripPrefix  = $state('');
  let timeoutMs    = $state(5000);
  let enabled      = $state(true);

  // Targets
  let targets = $state([{ url: '', weight: 1, headerMatchName: '', headerMatchValue: '' }]);

  // Policies — Rate Limit
  let rlEnabled = $state(false);
  let rlRps     = $state(100);
  let rlBurst   = $state(20);
  let rlTimeout = $state(0);

  // Policies — Circuit Breaker
  let cbEnabled  = $state(false);
  let cbFailure  = $state(50);
  let cbWait     = $state(60);
  let cbWindow   = $state(10);

  // Policies — Cache
  let cacheEnabled    = $state(false);
  let cacheTtl        = $state(300);
  let cacheKeyStrategy = $state('METHOD_PATH_QUERY');

  // Policies — Audit
  let auditEnabled = $state(false);
  let auditStore   = $state('database');

  // Headers
  let reqHeaders  = $state([]);   // [{ key, value }]
  let respHeaders = $state([]);

  let excludeReqList  = $state([]);
  let excludeRespList = $state([]);
  let authFwdList     = $state([]);

  let newExclReq  = $state('');
  let newExclResp = $state('');
  let newAuthFwd  = $state('');

  // ── LB options derived from routing type ──────────────────────────────────
  let lbOptions = $derived(ROUTING_LB_OPTIONS[routingType] ?? ROUTING_LB_OPTIONS.PATH);

  // When routing type changes, reset LB to first allowed option
  function onRoutingTypeChange() {
    const opts = ROUTING_LB_OPTIONS[routingType] ?? ROUTING_LB_OPTIONS.PATH;
    lbType = opts[0][0];
  }

  // ── Populate from existing route (edit mode) ──────────────────────────────
  $effect(() => {
    if (route) {
      name        = route.name ?? '';
      pathPattern = route['path-pattern'] ?? '';
      const rt    = route['routing-type'] || 'PATH';
      routingType = rt === 'HEADER' ? 'TRAFFIC_SPLIT' : rt;
      const lbOpts = ROUTING_LB_OPTIONS[routingType] ?? ROUTING_LB_OPTIONS.PATH;
      const lb     = route['load-balancer-type'] || lbOpts[0][0];
      lbType       = lbOpts.some(([v]) => v === lb) ? lb : lbOpts[0][0];
      stripPrefix  = route['strip-prefix'] ?? '';
      timeoutMs    = route['timeout-ms'] > 0 ? route['timeout-ms'] : 5000;
      enabled      = route.enabled ?? true;

      const tgts = (route.targets?.length ? route.targets : [{ url: '', weight: 1 }]);
      targets = tgts.map(t => ({
        url:             t.url ?? '',
        weight:          t.weight ?? 1,
        headerMatchName:  t['header-match-name'] ?? '',
        headerMatchValue: t['header-match-value'] ?? '',
      }));

      const rl = route['rate-limit-policy'];
      rlEnabled = rl?.enabled ?? false;
      rlRps     = rl?.['requests-per-second'] ?? 100;
      rlBurst   = rl?.burst ?? 20;
      rlTimeout = rl?.['timeout-duration-ms'] ?? 0;

      const cb = route['circuit-breaker-policy'];
      cbEnabled = cb?.enabled ?? false;
      cbFailure = cb?.['failure-rate-threshold'] ?? 50;
      cbWait    = cb?.['wait-duration-seconds'] ?? 60;
      cbWindow  = cb?.['sliding-window-size'] ?? 10;

      const cache = route['cache-policy'];
      cacheEnabled     = cache?.enabled ?? false;
      cacheTtl         = cache?.['ttl-seconds'] ?? 300;
      cacheKeyStrategy = cache?.['cache-key-strategy'] || 'METHOD_PATH_QUERY';

      auditEnabled = route['audit-enabled'] ?? false;
      auditStore   = route['audit-store'] || 'database';

      const hdr = route['header-rules'] ?? {};
      reqHeaders  = Object.entries(hdr['add-request']  ?? {}).map(([key,value]) => ({ key, value }));
      respHeaders = Object.entries(hdr['add-response'] ?? {}).map(([key,value]) => ({ key, value }));
      excludeReqList  = [...(hdr['exclude-request']  ?? [])];
      excludeRespList = [...(hdr['exclude-response'] ?? [])];
      authFwdList     = [...(route['auth-forward-headers'] ?? [])];
    }
  });

  // ── Target helpers ──────────────────────────────────────────────────────────
  function addTarget()      { targets = [...targets, { url: '', weight: 1, headerMatchName: '', headerMatchValue: '' }]; }
  function removeTarget(i)  { targets = targets.filter((_, idx) => idx !== i); }

  // ── Header helpers ──────────────────────────────────────────────────────────
  function addReqHeader()   { reqHeaders  = [...reqHeaders,  { key: '', value: '' }]; }
  function addRespHeader()  { respHeaders = [...respHeaders, { key: '', value: '' }]; }
  function removeReqHeader(i)  { reqHeaders  = reqHeaders.filter((_,idx) => idx !== i); }
  function removeRespHeader(i) { respHeaders = respHeaders.filter((_,idx) => idx !== i); }

  // ── Chip helpers ─────────────────────────────────────────────────────────────
  function addChip(list, val, clear) {
    const v = val.trim();
    if (v) { list.push(v); clear(); }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  async function save() {
    if (!name.trim() || !pathPattern.trim()) {
      showToast('Name and Path Pattern are required.', 'warning');
      return;
    }
    if (!targets.some(t => t.url.trim())) {
      showToast('Add at least one target URL.', 'warning');
      return;
    }
    const payload = buildPayload();
    try {
      if (mode === 'create') {
        await api.createRoute(payload);
        showToast('Route created successfully.', 'success');
      } else {
        await api.updateRoute(route.id, payload);
        showToast('Route updated successfully.', 'success');
      }
      await onsave?.();
    } catch (e) {
      showToast(`Save failed: ${e.message}`, 'error');
    }
  }

  function buildPayload() {
    const base = route ?? {};
    return {
      ...base,
      name,
      'path-pattern':       pathPattern,
      'routing-type':       routingType,
      'load-balancer-type': lbType,
      'strip-prefix':       stripPrefix.trim() || null,
      'timeout-ms':         Number(timeoutMs),
      'header-match-name':  null,
      'header-match-value': null,
      enabled,
      targets: targets
        .filter(t => t.url.trim())
        .map(t => ({
          url:                t.url,
          weight:             Number(t.weight),
          'header-match-name':  t.headerMatchName.trim() || null,
          'header-match-value': t.headerMatchValue.trim() || null,
        })),
      'rate-limit-policy': rlEnabled ? {
        enabled: true,
        'requests-per-second': Number(rlRps),
        burst: Number(rlBurst),
        'timeout-duration-ms': Number(rlTimeout),
      } : null,
      'circuit-breaker-policy': cbEnabled ? {
        enabled: true,
        'failure-rate-threshold': Number(cbFailure),
        'wait-duration-seconds':  Number(cbWait),
        'sliding-window-size':    Number(cbWindow),
      } : null,
      'cache-policy': cacheEnabled ? {
        enabled: true,
        'ttl-seconds':         Number(cacheTtl),
        'cache-key-strategy':  cacheKeyStrategy,
      } : null,
      'audit-enabled': auditEnabled,
      'audit-store':   auditStore,
      'header-rules': {
        'add-request':      Object.fromEntries(reqHeaders.filter(h => h.key.trim()).map(h => [h.key, h.value])),
        'add-response':     Object.fromEntries(respHeaders.filter(h => h.key.trim()).map(h => [h.key, h.value])),
        'exclude-request':  [...excludeReqList],
        'exclude-response': [...excludeRespList],
      },
      'auth-forward-headers': [...authFwdList],
    };
  }

  const tabLabels = ['Basic', 'Targets', 'Policies', 'Headers'];

  const inputCss = 'w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white';
  const labelCss = 'block text-sm font-medium text-gray-700 mb-1';
  const numInputCss = 'border border-gray-300 rounded px-2 py-1.5 text-xs w-full';
  const hdrInputCss = 'flex-1 border border-gray-300 rounded px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500';
  const chipInputCss = 'w-full border border-gray-300 rounded px-3 py-1.5 text-sm mb-2 focus:outline-none focus:ring-2 focus:ring-blue-500';
</script>

<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
  <div class="bg-white rounded-xl shadow-2xl w-full max-w-4xl mx-4 max-h-[90vh] flex flex-col overflow-hidden">

    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50 flex-shrink-0">
      <span class="text-lg font-semibold text-gray-800">
        {mode === 'create' ? 'New Route' : `Edit — ${route?.name ?? ''}`}
      </span>
      <button class="p-1.5 text-gray-400 hover:text-gray-600 rounded transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i>
      </button>
    </div>

    <!-- Tab nav -->
    <div class="flex border-b border-gray-200 bg-white px-4 flex-shrink-0">
      {#each tabLabels as label, i}
        <button
          class={activeTab === i
            ? 'cursor-pointer select-none px-4 py-3 text-sm font-medium text-blue-600 border-b-2 border-blue-600 -mb-px bg-white whitespace-nowrap'
            : 'cursor-pointer select-none px-4 py-3 text-sm font-medium text-gray-500 hover:text-gray-700 whitespace-nowrap'}
          onclick={() => activeTab = i}
        >{label}</button>
      {/each}
    </div>

    <!-- Tab content -->
    <div class="flex-1 overflow-y-auto">

      <!-- ── Tab 0: Basic ──────────────────────────────────────────────── -->
      {#if activeTab === 0}
        <div class="p-6 space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="flex flex-col">
              <span class={labelCss}>Name *</span>
              <input type="text" class={inputCss} placeholder="users-service" bind:value={name} />
            </div>
            <div class="flex flex-col">
              <span class={labelCss}>Path Pattern *</span>
              <input type="text" class={inputCss} placeholder="/api/users" bind:value={pathPattern} />
            </div>
            <div class="flex flex-col">
              <span class={labelCss}>Routing Type</span>
              <select class={inputCss} bind:value={routingType} onchange={onRoutingTypeChange}>
                <option value="PATH">PATH</option>
                <option value="REGEX">REGEX</option>
                <option value="TRAFFIC_SPLIT">TRAFFIC SPLIT</option>
              </select>
            </div>
            <div class="flex flex-col">
              <span class={labelCss}>Load Balancer</span>
              <select class={inputCss} bind:value={lbType}>
                {#each lbOptions as [val, label]}
                  <option value={val}>{label}</option>
                {/each}
              </select>
            </div>
            <div class="flex flex-col">
              <span class={labelCss}>Strip Prefix</span>
              <input type="text" class={inputCss} placeholder="/api/v1" bind:value={stripPrefix} />
            </div>
            <div class="flex flex-col">
              <span class={labelCss}>Timeout (ms)</span>
              <input type="number" class={inputCss} min="100" max="300000" bind:value={timeoutMs} />
            </div>
          </div>
          <div class="flex items-center gap-2 mt-2">
            <input type="checkbox" class="w-4 h-4 rounded border-gray-300 text-blue-600" bind:checked={enabled} />
            <span class="text-sm font-medium text-gray-700">Route Enabled</span>
          </div>
        </div>
      {/if}

      <!-- ── Tab 1: Targets ────────────────────────────────────────────── -->
      {#if activeTab === 1}
        <div class="p-6">
          <div class="flex items-center justify-between mb-4">
            <span class="text-sm font-semibold text-gray-700">Target Servers</span>
            <button
              class="flex items-center gap-2 px-3 py-1.5 bg-gray-100 text-gray-700 rounded-md text-sm hover:bg-gray-200 transition-colors"
              onclick={addTarget}
            ><i class="fas fa-plus"></i> Add Target</button>
          </div>
          <div class="space-y-2">
            {#each targets as target, i (i)}
              <div class="flex items-end gap-2 p-3 bg-gray-50 rounded-lg border border-gray-200">
                <div class="flex-1 flex flex-col">
                  <span class="text-xs font-medium text-gray-600 mb-1">URL</span>
                  <input type="text" class="flex-1 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" placeholder="http://backend:8080" bind:value={target.url} />
                </div>
                {#if lbType === 'WEIGHTED'}
                  <div class="flex flex-col">
                    <span class="text-xs font-medium text-gray-600 mb-1">Weight</span>
                    <input type="number" class="w-20 border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" min="1" max="100" bind:value={target.weight} />
                  </div>
                {/if}
                {#if lbType === 'HEADER'}
                  <div class="flex gap-2">
                    <div class="flex flex-col">
                      <span class="text-xs font-medium text-gray-600 mb-1">Header Name</span>
                      <input type="text" class={hdrInputCss} placeholder="X-User-Group" bind:value={target.headerMatchName} />
                    </div>
                    <div class="flex flex-col">
                      <span class="text-xs font-medium text-gray-600 mb-1">Expected Value</span>
                      <input type="text" class={hdrInputCss} placeholder="expected-value" bind:value={target.headerMatchValue} />
                    </div>
                  </div>
                {/if}
                <button
                  class="mb-0.5 p-1.5 text-red-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors self-end"
                  onclick={() => removeTarget(i)}
                ><i class="fas fa-times"></i></button>
              </div>
            {/each}
          </div>
        </div>
      {/if}

      <!-- ── Tab 2: Policies ───────────────────────────────────────────── -->
      {#if activeTab === 2}
        <div class="p-6 space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <!-- Rate Limit -->
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <div class="flex items-center gap-2 mb-3">
                <input type="checkbox" class="w-4 h-4 rounded border-gray-300 text-blue-600" bind:checked={rlEnabled} />
                <span class="text-sm font-semibold text-gray-700">Rate Limit</span>
              </div>
              {#if rlEnabled}
                <div class="grid grid-cols-3 gap-2">
                  {#each [['Req/s', 'rlRps', 1, 100000], ['Burst', 'rlBurst', 0, 100000], ['Timeout ms', 'rlTimeout', 0, 300000]] as [label]}
                    <div class="flex flex-col">
                      <span class="text-xs font-medium text-gray-600 mb-1">{label}</span>
                      {#if label === 'Req/s'}
                        <input type="number" class={numInputCss} min="1" max="100000" bind:value={rlRps} />
                      {:else if label === 'Burst'}
                        <input type="number" class={numInputCss} min="0" max="100000" bind:value={rlBurst} />
                      {:else}
                        <input type="number" class={numInputCss} min="0" max="300000" bind:value={rlTimeout} />
                      {/if}
                    </div>
                  {/each}
                </div>
              {/if}
            </div>

            <!-- Circuit Breaker -->
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <div class="flex items-center gap-2 mb-3">
                <input type="checkbox" class="w-4 h-4 rounded border-gray-300 text-blue-600" bind:checked={cbEnabled} />
                <span class="text-sm font-semibold text-gray-700">Circuit Breaker</span>
              </div>
              {#if cbEnabled}
                <div class="grid grid-cols-3 gap-2">
                  {#each ['Failure %', 'Wait (s)', 'Window'] as label}
                    <div class="flex flex-col">
                      <span class="text-xs font-medium text-gray-600 mb-1">{label}</span>
                      {#if label === 'Failure %'}
                        <input type="number" class={numInputCss} min="1" max="100" bind:value={cbFailure} />
                      {:else if label === 'Wait (s)'}
                        <input type="number" class={numInputCss} min="1" max="3600" bind:value={cbWait} />
                      {:else}
                        <input type="number" class={numInputCss} min="1" max="100" bind:value={cbWindow} />
                      {/if}
                    </div>
                  {/each}
                </div>
              {/if}
            </div>

            <!-- Cache -->
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <div class="flex items-center gap-2 mb-3">
                <input type="checkbox" class="w-4 h-4 rounded border-gray-300 text-blue-600" bind:checked={cacheEnabled} />
                <span class="text-sm font-semibold text-gray-700">Cache</span>
              </div>
              {#if cacheEnabled}
                <div class="grid grid-cols-2 gap-2">
                  <div class="flex flex-col">
                    <span class="text-xs font-medium text-gray-600 mb-1">TTL (s)</span>
                    <input type="number" class={numInputCss} min="1" max="86400" bind:value={cacheTtl} />
                  </div>
                  <div class="flex flex-col">
                    <span class="text-xs font-medium text-gray-600 mb-1">Key Strategy</span>
                    <select class="border border-gray-300 rounded px-2 py-1.5 text-xs w-full bg-white" bind:value={cacheKeyStrategy}>
                      <option value="METHOD_PATH">Method+Path</option>
                      <option value="METHOD_PATH_QUERY">Method+Path+Query</option>
                    </select>
                  </div>
                </div>
              {/if}
            </div>

            <!-- Audit -->
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <div class="flex items-center gap-2 mb-3">
                <input type="checkbox" class="w-4 h-4 rounded border-gray-300 text-blue-600" bind:checked={auditEnabled} />
                <span class="text-sm font-semibold text-gray-700">Audit</span>
              </div>
              {#if auditEnabled}
                <div class="flex flex-col">
                  <span class="text-xs font-medium text-gray-600 mb-1">Audit Store</span>
                  <select class="border border-gray-300 rounded px-2 py-1.5 text-sm w-full bg-white" bind:value={auditStore}>
                    <option value="database">Database</option>
                    <option value="file">File</option>
                  </select>
                </div>
              {/if}
            </div>
          </div>
        </div>
      {/if}

      <!-- ── Tab 3: Headers ────────────────────────────────────────────── -->
      {#if activeTab === 3}
        <div class="p-6 space-y-4">
          <!-- Add request / response headers -->
          <div class="grid grid-cols-2 gap-4">
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <div class="flex items-center justify-between mb-3">
                <span class="text-sm font-semibold text-gray-700">Add Request Headers</span>
                <button class="p-1 rounded text-gray-500 hover:text-blue-600 hover:bg-blue-50 transition-colors" onclick={addReqHeader}>
                  <i class="fas fa-plus"></i>
                </button>
              </div>
              <div class="space-y-2">
                {#each reqHeaders as h, i (i)}
                  <div class="flex items-center gap-2">
                    <input type="text" class={hdrInputCss} placeholder="X-Header-Name" bind:value={h.key} />
                    <input type="text" class={hdrInputCss} placeholder="header-value"  bind:value={h.value} />
                    <button class="p-1 text-red-400 hover:text-red-600 rounded transition-colors flex-shrink-0" onclick={() => removeReqHeader(i)}>
                      <i class="fas fa-times"></i>
                    </button>
                  </div>
                {/each}
              </div>
            </div>
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <div class="flex items-center justify-between mb-3">
                <span class="text-sm font-semibold text-gray-700">Add Response Headers</span>
                <button class="p-1 rounded text-gray-500 hover:text-blue-600 hover:bg-blue-50 transition-colors" onclick={addRespHeader}>
                  <i class="fas fa-plus"></i>
                </button>
              </div>
              <div class="space-y-2">
                {#each respHeaders as h, i (i)}
                  <div class="flex items-center gap-2">
                    <input type="text" class={hdrInputCss} placeholder="X-Header-Name" bind:value={h.key} />
                    <input type="text" class={hdrInputCss} placeholder="header-value"  bind:value={h.value} />
                    <button class="p-1 text-red-400 hover:text-red-600 rounded transition-colors flex-shrink-0" onclick={() => removeRespHeader(i)}>
                      <i class="fas fa-times"></i>
                    </button>
                  </div>
                {/each}
              </div>
            </div>
          </div>

          <!-- Chip sections -->
          <div class="grid grid-cols-2 gap-4">
            <!-- Exclude Request Headers -->
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <span class="text-sm font-semibold text-gray-700 block mb-2">Exclude Request Headers</span>
              <input type="text" class={chipInputCss} placeholder="Cookie" bind:value={newExclReq} />
              <div class="flex gap-2 items-end mb-2">
                <button class="px-3 py-1.5 bg-gray-200 text-gray-700 rounded text-sm hover:bg-gray-300 transition-colors"
                  onclick={() => { addChip(excludeReqList, newExclReq, () => newExclReq = ''); excludeReqList = excludeReqList; }}>
                  Add
                </button>
              </div>
              <div class="flex flex-wrap gap-1 mt-2">
                {#each excludeReqList as chip, i}
                  <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-100 text-blue-700 rounded-full text-xs font-medium">
                    {chip}
                    <button class="cursor-pointer font-bold hover:text-blue-900" onclick={() => { excludeReqList = excludeReqList.filter((_,idx) => idx !== i); }}>×</button>
                  </span>
                {/each}
              </div>
            </div>

            <!-- Exclude Response Headers -->
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <span class="text-sm font-semibold text-gray-700 block mb-2">Exclude Response Headers</span>
              <input type="text" class={chipInputCss} placeholder="Server" bind:value={newExclResp} />
              <div class="flex gap-2 items-end mb-2">
                <button class="px-3 py-1.5 bg-gray-200 text-gray-700 rounded text-sm hover:bg-gray-300 transition-colors"
                  onclick={() => { addChip(excludeRespList, newExclResp, () => newExclResp = ''); excludeRespList = excludeRespList; }}>
                  Add
                </button>
              </div>
              <div class="flex flex-wrap gap-1 mt-2">
                {#each excludeRespList as chip, i}
                  <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-100 text-blue-700 rounded-full text-xs font-medium">
                    {chip}
                    <button class="cursor-pointer font-bold hover:text-blue-900" onclick={() => { excludeRespList = excludeRespList.filter((_,idx) => idx !== i); }}>×</button>
                  </span>
                {/each}
              </div>
            </div>
          </div>

          <!-- Auth forward headers -->
          <div class="grid grid-cols-1 gap-4">
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <span class="text-sm font-semibold text-gray-700 block mb-2">Auth Forward Headers</span>
              <input type="text" class={chipInputCss} placeholder="Authorization" bind:value={newAuthFwd} />
              <div class="flex gap-2 items-end mb-2">
                <button class="px-3 py-1.5 bg-gray-200 text-gray-700 rounded text-sm hover:bg-gray-300 transition-colors"
                  onclick={() => { addChip(authFwdList, newAuthFwd, () => newAuthFwd = ''); authFwdList = authFwdList; }}>
                  Add
                </button>
              </div>
              <div class="flex flex-wrap gap-1 mt-2">
                {#each authFwdList as chip, i}
                  <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-100 text-blue-700 rounded-full text-xs font-medium">
                    {chip}
                    <button class="cursor-pointer font-bold hover:text-blue-900" onclick={() => { authFwdList = authFwdList.filter((_,idx) => idx !== i); }}>×</button>
                  </span>
                {/each}
              </div>
            </div>
          </div>
        </div>
      {/if}
    </div>

    <!-- Footer -->
    <div class="flex justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50 flex-shrink-0">
      <button class="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-md text-sm font-medium hover:bg-gray-200 transition-colors" onclick={onclose}>
        <i class="fas fa-times"></i> Cancel
      </button>
      <button class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-md text-sm font-medium hover:bg-blue-700 transition-colors" onclick={save}>
        <i class="fas fa-check"></i> {mode === 'create' ? 'Create Route' : 'Save Changes'}
      </button>
    </div>
  </div>
</div>
