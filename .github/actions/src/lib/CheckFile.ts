import { getOctokit } from "@actions/github";
import { ALLOWED_STATUSES, GITHUB_TOKEN } from "src/utils/constants";
import { AUTHOR_RE, FILE_RE, matchAll } from "src/utils/regex";
import { EIP, File, ParsedFile, PR, Request } from "src/utils/types";
import frontmatter, { FrontMatterResult } from "front-matter";
import { context } from "@actions/github/lib/utils";
import fetch from "node-fetch";

export const parseFile = async (file: File): Promise<ParsedFile> => {
  const fetchRawFile = (file: File): Promise<any> =>
    fetch(file.contents_url, { method: "get" }).then((res: any) => res.json());
  const decodeContent = (rawFile: any) =>
    Buffer.from(rawFile.content, "base64").toString();
  const rawFile = await fetchRawFile(file);

  return { path: rawFile.path, name: file.filename, status: file.status, content: frontmatter(decodeContent(rawFile))};
};

export const getFiles = async (request: Request) => {
  const files = request.data.files;

  console.log("---------");
  console.log(`${files.length} file found!` || "no files");

  const contents = await Promise.all(files.map(parseFile));
  // contents.map((file: ParsedFile) => {
  //   console.log(`file name ${file.name} has length ${file.content.body.length}`)
  // }
    
  // );
  console.log("---------");
  
  return { files: contents }
}

export const getAuthors = async (rawAuthorList: string) => {
  const resolveAuthor = async (author: string) => {
    if (author[0] === "@") {
      return author.toLowerCase();
    } else {
      // Email address
      const queriedUser = await findUserByEmail(author);
      return (queriedUser || author).toLowerCase();
    }
  };

  const findUserByEmail = async (email: string): Promise<string | undefined> => {
    const Github = getOctokit(process.env.GITHUB_TOKEN || "");
    
    console.log(`Searching for user by email: ${email}`)
    const { data: results } = await Github.search.users({ q: email })
    console.log(`\t found ${results.total_count} results`)
    
    if (results.total_count > 0) {
      console.log(`\t Recording mapping from ${email} to ${results.items[0].login}`);
      return "@" + results.items[0].login;
    }
    console.log("No github user found, using email instead");
  };

  const authors = matchAll(rawAuthorList, AUTHOR_RE, 1);
  const resolved = await Promise.all(authors.map(resolveAuthor));

  return new Set(resolved)
};

type CheckFileReturn = Promise<[EIP | null, string | null]>;

export const checkFile = async ({ data: pr }: PR, parsedFile: ParsedFile): CheckFileReturn => {
  const Github = getOctokit(GITHUB_TOKEN);
  const fileName = parsedFile.path;

  console.log(`---- check_file: ${fileName}`);
  try {
  const match = fileName.search(FILE_RE);
  if (match === -1) {
    return [null, `File ${fileName} is not an EIP`];
  }

  const eipNumMatch = fileName.match(/(\d+)/);
  if (!eipNumMatch) {
    throw "no eip number"
  }
  const eipNum = eipNumMatch[0]
  console.log(`Found EIP number as ${eipNum} for file name ${fileName}`);

  if (parsedFile.status == "added") {
    return [null, `Contains new file ${fileName}`];
  }

  console.log(
    `Getting file ${fileName} from ${pr.base.user.login}@${pr.base.repo.name}/${pr.base.sha}`
  );

  const basedata: FrontMatterResult<any> = parsedFile.content;
  console.log("got attributes...")
  console.log(basedata.attributes);

  const status = basedata.attributes["status"];
  console.log("----- Retrieving authors from EIP raw authors list")
  const authors = await getAuthors(basedata.attributes["author"]);
  console.log(`authors: ${authors}`)

  if (!ALLOWED_STATUSES.has(status.toLowerCase())) {
    return [
    null,
    `EIP ${eipNum} is in state ${status}, not Draft or Last Call`,
    ];
  }
  const eip = { number: eipNum, authors }
  
  console.log(`--------`)
  console.log(`eip attribute: ${basedata.attributes["eip"]}\textracted num: ${eipNum}`)
  if (basedata.attributes["eip"] !== parseInt(eipNum)) {
    return [
    eip,
    `EIP header in ${fileName} does not match: ${basedata.attributes["eip"]}`,
    ];
  }
  console.log(`eips in header + file name matched!`)

  // checking head <---> base
  console.log("------ Checking Head <--> Base commit consistency...")
  console.log(
    `Getting file ${fileName} from ${pr.base.user.login}@${pr.base.repo.name}/${pr.base.sha}`
  );
  const head = await Github.repos.getCommit({owner: context.repo.owner, repo: context.repo.repo, ref: pr.head.sha}); // ref=pr.head.sha
  if (!head.data.files) {
    throw "no files at head"
  }
  const headdata = await parseFile(head.data.files[0] as File).then(res => res.content);
  console.log("head commit attributes...");
  console.log(headdata.attributes);
  if (headdata.attributes["eip"] != parseInt(eipNum)) {
    console.log(`head and base commits had non-matching eip numbers; head: ${headdata.attributes["eip"]} -- base: ${eipNum}`)
    return [
    eip,
    `EIP header in modified file ${fileName} does not match: ${headdata.attributes["eip"]}`,
    ];
  } else if (
    headdata.attributes["status"].toLowerCase() !=
    basedata.attributes["status"].toLowerCase()
  ) {
    console.log(`A status change was detected; head: ${headdata.attributes["status"].toLowerCase()} -- base: ${basedata.attributes["status"].toLowerCase()}`)
    return [
    eip,
    `Trying to change EIP ${eipNum} state from ${basedata.attributes["status"]} to ${headdata.attributes["status"]}`,
    ];
  }
  console.log("No errors with the file were detected!")
  return [eip, null];
  } catch (e) {
  console.warn("Exception checking file %s", parsedFile.name);
  return [null, `Error checking file ${parsedFile.name}`];
  }
};