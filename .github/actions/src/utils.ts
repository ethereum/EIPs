import { File, ParsedFile, PR } from "./types";
import frontmatter from "front-matter";
import fetch from "node-fetch";
import { context, getOctokit } from "@actions/github";
import { AUTHOR_RE, matchAll } from "./regex";

export const parseFile = async (file: File): Promise<ParsedFile> => {
    const fetchRawFile = (file: File): Promise<any> =>
        fetch(file.contents_url, { method: "get" }).then((res) => res.json());
    const decodeContent = (rawFile: any) =>
        Buffer.from(rawFile.content, "base64").toString();
    const rawFile = await fetchRawFile(file);

    return { path: rawFile.path, name: rawFile.name, content: frontmatter(decodeContent(rawFile)) };
};

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
        const Github = getOctokit(process.env.GITHUB_TOKEN);
        
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

export const getApprovals = async (pr: PR) => {
    let approvals: Set<string> = new Set();
    approvals.add('@' + pr.data.user.login.toLowerCase())
    const Github = getOctokit(process.env.GITHUB_TOKEN);
    const {data: reviews} = await Github.pulls.listReviews({ owner: context.repo.owner, repo: context.repo.repo, pull_number: pr.data.number })
    console.log(`\t- ${reviews.length} reviews were found for the PR`)
  
    reviews.map(review => {
      if (review.state == "APPROVED") {
        approvals.add('@' + review.user.login.toLowerCase())
      }
    })
  
    const _approvals = [...approvals]
    console.log(`\t- Found approvers for pr number ${pr.data.number}: ${_approvals.join(" & ")}`)
    return _approvals
  }
