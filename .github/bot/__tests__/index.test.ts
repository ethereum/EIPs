import { __MAIN__ } from "src/utils";
const github: any = jest.createMockFromModule("@actions/github");

describe("jest should run", () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    jest.resetModules(); // Most important - it clears the cache
    process.env = { ...OLD_ENV }; // Make a copy
  });

  afterAll(() => {
    process.env = OLD_ENV; // Restore old environment
  });

  it("runs", async () => {
    await __MAIN__({
      GITHUB_TOKEN: "",
      NODE_ENV: "development",
      PULL_NUMBER: "6",
      BASE_SHA: "ded4fdfed04f6d5f486ec248ede66d6ba0546ef3",
      HEAD_SHA: "800fe8e8c47491dd2daab31256f4e48b358a7ba4",
      REPO_OWNER_NAME: "alita-moore",
      REPO_NAME: "EIPs",
      GITHUB_REPOSITORY: "alita-moore/EIPs"
    });
  });
});
