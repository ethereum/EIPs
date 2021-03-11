import { getOctokit } from "@actions/github";
import {
  GITHUB_TOKEN,
  FrontMatterAttributes,
  matchAll,
  AUTHOR_RE,
  File,
  ContentFile,
  EipStatus,
  getFilenameEipNum,
  FileStatus,
  ERRORS
} from "src/utils";
import frontmatter, { FrontMatterResult } from "front-matter";
import { context } from "@actions/github/lib/utils";
import { assertPr, assertEncoding } from "./Assertions";

export type FileDiff = {
  head: FormattedFile;
  base: FormattedFile;
};

export const getFileDiff = async (file: NonNullable<File>): Promise<FileDiff> => {
  const pr = await assertPr();
  const filename = file.filename;
  // Get and parse head and base file
  const base = await getParsedContent(filename, pr.base.sha);
  const head = await getParsedContent(filename, pr.head.sha);

  // Organize information cleanly
  return {
    head: await formatFile(head),
    base: await formatFile(base)
  };
};

export type FormattedFile = {
  eipNum: number;
  status: EipStatus;
  authors?: Set<string>;
  name: string;
  filenameEipNum: number;
};

const formatFile = async (file: ParsedContent): Promise<FormattedFile> => {
  const filenameEipNum = getFilenameEipNum(file.name);
  if (!filenameEipNum) {
    throw `Failed to extract eip number from file "${file.path}"`;
  }

  return {
    eipNum: file.content.attributes[FrontMatterAttributes.eip],
    status: file.content.attributes[FrontMatterAttributes.status].toLowerCase(),
    authors: await getAuthors(
      file.content.attributes[FrontMatterAttributes.author]
    ),
    name: file.name,
    filenameEipNum
  };
};

export type ParsedContent = {
  path: string;
  name: string;
  content: FrontMatterResult<any>;
};

const getParsedContent = async (
  filename: string,
  sha: string
): Promise<ParsedContent> => {
  const Github = getOctokit(GITHUB_TOKEN);
  const decodeData = (data: ContentFile) => {
    const encoding = data.encoding;
    assertEncoding(encoding, filename);
    return Buffer.from(data.content, encoding).toString();
  };

  // Collect the file contents at the given sha reference frame
  const data = (await Github.repos
    .getContent({
      owner: context.repo.owner,
      repo: context.repo.repo,
      path: filename,
      ref: sha
    })
    .then((res) => res.data)) as ContentFile;

  // Assert type assumptions
  if (!data?.content) {
    throw `requested file ${filename} at ref sha ${sha} contains no content`;
  }
  if (!data?.path) {
    throw `requested file ${filename} at ref sha ${sha} has no path`;
  }
  if (!data?.name) {
    throw `requested file ${filename} at ref sha ${sha} has no name`;
  }

  // Return parsed information
  return {
    path: data.path,
    name: data.name,
    content: frontmatter(decodeData(data))
  };
};

const getAuthors = async (rawAuthorList?: string) => {
  if (!rawAuthorList) return;

  const findUserByEmail = async (
    email: string
  ): Promise<string | undefined> => {
    const Github = getOctokit(GITHUB_TOKEN);
    const { data: results } = await Github.search.users({ q: email });
    if (results.total_count > 0 && results.items[0] !== undefined) {
      return "@" + results.items[0].login;
    }
    console.warn(`No github user found, using email instead: ${email}`);
    return undefined;
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

export const isFilePreexisting = (file: NonNullable<File>) => {
  if (file.status === FileStatus.added) {
    ERRORS.push(
      `File with name ${file.filename} is new and new files must be reviewed`
    );
    return false; // filters the files out
  }
  return true;
};
