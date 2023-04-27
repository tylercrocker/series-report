export function pluralize(string, count = 0) {
  switch(string) {
  case undefined:
  case null:
    return null;
  case 'Person':
  case 'person':
  case 'People':
  case 'people':
    return `${string[0] === 'P' ? 'P' : 'p'}${count === 1 ? 'erson' : 'eople'}`;
  case 'Series':
  case 'series':
    return string;
  default:
    return `${string}${count === 1 ? '' : 's'}`;
  }
}
