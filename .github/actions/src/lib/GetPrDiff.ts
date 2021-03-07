import { getOctokit } from "@actions/github";
import { ParsedFile, GITHUB_TOKEN, Commit, FrontMatterAttributes, PrDiff, matchAll, AUTHOR_RE, File } from "src/utils";
import frontmatter from "front-matter";

export const getPrFileDiff = async (baseCommit: Commit, headCommit: Commit, filename: string): Promise<PrDiff> => {
  // Get and parse head and base file
  const baseFile = baseCommit.files?.filter(
    (file) => file.filename === filename
  );
  const headFile = headCommit.files?.filter(
    (file) => file.filename === filename
  );

  if (!(headFile && headFile[0]) || !(baseFile && baseFile[0])) {
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

const parseFile = async (file: File): Promise<ParsedFile> => {
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

const getAuthors = async (rawAuthorList: string) => {
  const findUserByEmail = async (
    email: string
  ): Promise<string | undefined> => {
    const Github = getOctokit(GITHUB_TOKEN);
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