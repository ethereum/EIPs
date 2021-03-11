import {
  FILE_RE,
  ALLOWED_STATUSES,
  File,
  getFilenameEipNum,
  ERRORS
} from "src/utils";
import { FileDiff } from "./GetFileDiff";

export const checkEIP = ({ head, base }: FileDiff) => {
  // establish comparisons
  const headMatchesSelf = head.filenameEipNum === head.eipNum;
  const baseFileMatchesHead = base.filenameEipNum === head.eipNum;
  const baseMatchesHead = base.eipNum === head.eipNum;

  // Checks if most recent EIP matches self
  if (!headMatchesSelf) {
    ERRORS.push(`EIP header in file ${head.name} does not match: ${base.name}`);
  }

  // Check for EIP number change
  if (headMatchesSelf && !(baseMatchesHead || baseFileMatchesHead)) {
    ERRORS.push(
      `Base EIP has number ${base.eipNum} which was changed to head ${head.eipNum}; EIP number changing is not allowd`
    );
  }

  // Check if status was changed
  if (head.status !== base.status) {
    ERRORS.push(
      `Trying to change EIP ${head.eipNum} state from ${base.status} to ${head.status}`
    );
  }

  // Check if base statuses are not allowed
  else if (!ALLOWED_STATUSES.has(head.status)) {
    ERRORS.push(
      `${head.name} is in state ${head.status}, not ${[
        ...ALLOWED_STATUSES
      ].join(" or ")}`
    );
  }
};

export const isValidEipFilename = (file: NonNullable<File>) => {
  const filename = file.filename;

  // File name is formatted correctly and is in the EIPS folder
  const match = filename.search(FILE_RE);
  if (match === -1) {
    ERRORS.push(`Filename ${filename} is not in EIP format 'EIPS/eip-####.md'`);
    return false;
  }

  // EIP number is defined within the filename and can be parsed
  const filenameEipNum = getFilenameEipNum(filename);
  if (!filenameEipNum) {
    ERRORS.push(
      `No EIP number was found to be associated with filename ${filename}`
    );
    return false;
  }

  return true;
};
