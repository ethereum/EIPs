import { request } from "@octokit/request";
export declare const graphql: import("./types").graphql;
export { GraphQlQueryResponseData } from "./types";
export declare function withCustomRequest(customRequest: typeof request): import("./types").graphql;
