export const FILE_RE = /^EIPS\/eip-(\d+)\.md$/mg;
export const AUTHOR_RE = /[(<]([^>)]+)[>)]/mg;

/** 
 * This functionality is supported in es2020, but for the purposes
 * of compatibility (and because it's quite simple) it's built explicitly
 */
export const matchAll = (rawString: string, regex: RegExp, group: number): string[] => {
  let match = regex.exec(rawString);
  let matches: string[] = [];
  while (match != null) {
    matches.push(match[group]);
    match = regex.exec(rawString);
  }
  return matches;
}