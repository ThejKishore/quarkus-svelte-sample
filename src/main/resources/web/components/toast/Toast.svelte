<script>
  import { toasts } from '../../lib/toastStore.js';

  const bgMap = {
    success: '#22c55e',
    error:   '#ef4444',
    warning: '#f59e0b',
    info:    '#3b82f6',
  };
</script>

<div class="toast-container">
  {#each $toasts as t (t.id)}
    <div class="toast" style="background:{bgMap[t.type] ?? bgMap.info}">
      {t.message}
    </div>
  {/each}
</div>

<style>
  .toast-container {
    position: fixed;
    top: 1rem;
    right: 1rem;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
    max-width: 20rem;
  }
  .toast {
    color: #fff;
    padding: 0.75rem 1rem;
    border-radius: 0.5rem;
    box-shadow: 0 4px 12px rgba(0,0,0,.2);
    font-size: .875rem;
    font-weight: 500;
    animation: fadeIn 0.2s ease;
  }
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(-4px); }
    to   { opacity: 1; transform: translateY(0); }
  }
</style>
