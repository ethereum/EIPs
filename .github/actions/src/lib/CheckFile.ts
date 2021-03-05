import { getOctokit } from "@actions/github";
import {
  ALLOWED_STATUSES,
  EipStatus,
  FrontMatterAttributes,
  GITHUB_TOKEN
} from "src/utils/constants";
import { AUTHOR_RE, EIP_NUM_RE, FILE_RE, matchAll } from "src/utils/regex";
import { EIP, File, ParsedFile, PR, Request } from "src/utils/types";
import frontmatter, {
  FrontMatterResult,
  FrontMatterOptions
} from "front-matter";
import { context } from "@actions/github/lib/utils";
import fetch from "node-fetch";

type GetFilesReturn = Promise<{
  files: ParsedFile[];
}>;

type CheckFileReturn = Promise<[EIP | null, string | null]>;

export const checkFile = async (
  pr: PR,
  parsedFile: ParsedFile
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
    const { base, head } = await getBaseAndHeadFile(pr, filename);

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

export const parseFile = async (file: File): Promise<ParsedFile> => {
  // TODO: there's probably a way to do this with octokit (better for maintaining types)
  const fetchRawFile = (file: File): Promise<any> =>
    fetch(file.contents_url, { method: "get" }).then((res: any) => res.json());
  const decodeContent = (rawFile: any) =>
    Buffer.from(rawFile.content, "base64").toString();

  const rawFile = await fetchRawFile(file);

  return {
    path: rawFile.path,
    name: file.filename,
    status: file.status,
    content: frontmatter(decodeContent(rawFile))
  };
};

export const getFiles = async (request: Request): GetFilesReturn => {
  const files = request.data.files;
  const contents = await Promise.all(files.map(parseFile));
  return { files: contents };
};

type PrDiff = {
  head: { eipNum: number; status: EipStatus; authors: Set<string> };
  base: { eipNum: number; status: EipStatus; authors: Set<string> };
};

const getBaseAndHeadFile = async (
  { data: pr }: PR,
  filename: string
): Promise<PrDiff> => {
  const Github = getOctokit(GITHUB_TOKEN);

  // Get base and head commits
  const baseCommit = await Github.repos
    .getCommit({
      owner: context.repo.owner,
      repo: context.repo.repo,
      ref: pr.base.sha
    })
    .then((res) => res.data);
  const headCommit = await Github.repos
    .getCommit({
      owner: context.repo.owner,
      repo: context.repo.repo,
      ref: pr.head.sha
    })
    .then((res) => res.data);

  // Get and parse head and base file
  const baseFile = baseCommit.files?.filter(
    (file) => file.filename === filename
  );
  const headFile = headCommit.files?.filter(
    (file) => file.filename === filename
  );
  if (!baseFile || !headFile) {
    throw `Failed to find file at head and base: the requested file '${filename}' is either new or was renamed`;
  }
  const baseParsedFile = await parseFile(baseFile[0] as File);
  const headParsedFile = await parseFile(headFile[0] as File);

  // Organize information cleanly
  return {
    head: {
      eipNum: headParsedFile.content.attributes[FrontMatterAttributes.eip],
      status: headParsedFile.content.attributes[
        FrontMatterAttributes.status
      ].toLowerCase(),
      authors: await getAuthors(
        headParsedFile.content.attributes[FrontMatterAttributes.author]
      )
    },
    base: {
      eipNum: baseParsedFile.content.attributes[FrontMatterAttributes.eip],
      status: baseParsedFile.content.attributes[
        FrontMatterAttributes.status
      ].toLowerCase(),
      authors: await getAuthors(
        baseParsedFile.content.attributes[FrontMatterAttributes.author]
      )
    }
  };
};

const getAuthors = async (rawAuthorList: string) => {
  const findUserByEmail = async (
    email: string
  ): Promise<string | undefined> => {
    const Github = getOctokit(process.env.GITHUB_TOKEN || "");
    const { data: results } = await Github.search.users({ q: email });
    if (results.total_count > 0) {
      return "@" + results.items[0].login;
    }
    console.warn(`No github user found, using email instead: ${email}`);
  };

  const resolveAuthor = async (author: string) => {
    if (author[0] === "@") {
      return author.toLowerCase();
    } else {
      // Email address
      const queriedUser = await findUserByEmail(author);
      return (queriedUser || author).toLowerCase();
    }
  };

  const authors = matchAll(rawAuthorList, AUTHOR_RE, 1);
  const resolved = await Promise.all(authors.map(resolveAuthor));
  return new Set(resolved);
};
