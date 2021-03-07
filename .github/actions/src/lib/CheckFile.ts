
import { EIP_NUM_RE, FILE_RE, ALLOWED_STATUSES,
  EipStatus,
  FrontMatterAttributes,
  GITHUB_TOKEN,
  PrDiff
} from "src/utils";
import { EIP, ParsedFile, PR, Request } from "src/utils/types";

type GetFilesReturn = Promise<{
  files: ParsedFile[];
}>;

type CheckFileReturn = Promise<[EIP | null, string | null]>;

/** Only called for files that were changed (not new or renamed) */
export const checkFile = async (
  { base, head }: PrDiff
): CheckFileReturn => {
  const filename = parsedFile.path;

  try {
    // New files should be manually reviewed
    if (parsedFile.status == "added") {
      return [null, `Contains new file ${filename}`];
    }

    // File name is formatted as an EIP
    const match = filename.search(FILE_RE);
    if (match === -1) {
      return [null, `File ${filename} is not an EIP`];
    }

    // EIP number is defined
    const eipNumMatch = filename.match(EIP_NUM_RE);
    const filenameEipNum = eipNumMatch && parseInt(eipNumMatch[0]);
    if (!filenameEipNum) {
      return [
        null,
        `No EIP number was found to be associated with file name ${filename}`
      ];
    }

    // Collect pr diff
    const { base, head } = await getBaseAndHeadFile( filename);

    // Verify EIP number in the file name matches the most recent commit's attribute
    if (head.eipNum !== filenameEipNum) {
      return [
        null,
        `EIP header in modified file ${filename} does not match: ${filenameEipNum}`
      ];
    }
    const eip: EIP = { number: head.eipNum.toString(), authors: head.authors };

    // Check status
    if (head.status !== base.status) {
      return [
        eip,
        `Trying to change EIP ${head.eipNum} state from ${base.status} to ${head.status}`
      ];
    } else if (!ALLOWED_STATUSES.has(base.status)) {
      return [
        null,
        `EIP ${filenameEipNum} is in state ${status}, not Draft or Last Call`
      ];
    }

    // no errors found...
    return [eip, null];
  } catch (e) {
    console.warn(`Error checking file ${parsedFile.name}: ${e}`);
    return [null, `Error checking file ${parsedFile.name}: ${e}`];
  }
};

export const getFiles = async (request: Request): GetFilesReturn => {
  const files = request.data.files;
  const contents = await Promise.all(files.map(parseFile));
  return { files: contents };
};


