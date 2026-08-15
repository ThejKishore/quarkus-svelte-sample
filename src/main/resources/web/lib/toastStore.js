import { writable } from 'svelte/store';

export const toasts = writable([]);

let nextId = 0;

/**
 * Show a toast notification.
 * @param {string} message
 * @param {'success'|'error'|'warning'|'info'} type
 */
export function showToast(message, type = 'info') {
  const id = ++nextId;
  toasts.update(list => [...list, { id, message, type }]);
  setTimeout(() => {
    toasts.update(list => list.filter(t => t.id !== id));
  }, 3500);
}
