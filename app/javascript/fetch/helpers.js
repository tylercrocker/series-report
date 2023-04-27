import { pluralize } from '../string/helpers'

export const CSRF_PARAM = document.querySelector('meta[name="csrf-param"]').content;
export const CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]').content;
export const JSON_ACCEPT_HEADERS = new Headers({
  'Accept': 'application/json',
});

export const JSON_CONTENT_HEADERS = new Headers({
  'Content-Type': 'application/json',
});

export function buildRoute(options = {}) {
  const splitClass = options.type ? options.type.toLowerCase().split('::') : [];

  const baseRoute = options.basePath || pluralize(splitClass[0]);
  const type = splitClass[1] ? `/${splitClass[1].toLowerCase()}` : '';
  const slug = options.slug ? `/${options.slug}` : '';
  const id = options.id ? `/${options.id}` : '';

  return `/${baseRoute}${type}${slug}${id}`;
}
