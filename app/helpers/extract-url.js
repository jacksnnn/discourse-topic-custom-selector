// helpers/extract-url.js
import { helper } from '@ember/component/helper';

export function extractUrl([fieldValue]) {
  // Assuming the URL is the part after the last slash
  const url = fieldValue.split('/').pop();
  return url;
}

export default helper(extractUrl);