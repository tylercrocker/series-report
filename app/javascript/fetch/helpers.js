export const CSRF_PARAM = document.querySelector('meta[name="csrf-param"]').content;
export const CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]').content;
export const JSON_HEADERS = new Headers({'Content-Type': 'application/json'});
