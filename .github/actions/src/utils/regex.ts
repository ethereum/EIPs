export const FILE_RE = /^EIPS\/eip-(\d+)\.md$/gm;
export const AUTHOR_RE = /[(<]([^>)]+)[>)]/gm;

/**
 * This functionality is supported in es2020, but for the purposes
 * of compatibility (and because it's quite simple) it's built explicitly
 */
export const matchAll = (
  rawString: string,
  regex: RegExp,
  group: number
): string[] => {
  let match = regex.exec(rawString);
  let matches: string[] = [];
  while (match != null) {
    matches.push(match[group]);
    match = regex.exec(rawString);
  }
  return matches;
};

/** to find the EIP number in a file name */
export const EIP_NUM_RE = /(\d+)/;
