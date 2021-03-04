import { getOctokit } from "@actions/github";
import frontmatter, { FrontMatterResult } from "front-matter";

export type Github = ReturnType<typeof getOctokit>;
const Github = getOctokit("fake");

export type Request = UnPromisify<ReturnType<typeof Github.repos.compareCommits>>;

type UnPromisify<T> = T extends Promise<infer U> ? U : T;
export type PR = UnPromisify<ReturnType<typeof Github.pulls.get>>;

export type CompareCommits = UnPromisify<ReturnType<typeof Github.repos.compareCommits>>;
var _compared_: CompareCommits;
export type Files = typeof _compared_.data.files;
var _files_: Files;
export type File = typeof _files_[0];

export type ParsedFile = {
    path: string,
    name: string,
    status: string,
    content: FrontMatterResult<any>
}

export type EIP = {
  number: string;
  authors: Set<string>;
}

export type PostComment = {
  errors: string[],
  pr: PR,
  eips: EIP[]
}