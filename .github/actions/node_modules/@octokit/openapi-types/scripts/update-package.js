const { writeFileSync } = require("fs");

if (!process.env.OCTOKIT_OPENAPI_VERSION) {
  throw new Error("OCTOKIT_OPENAPI_VERSION is not set");
}

const pkg = require("../package.json");

if (!pkg.octokit) {
  pkg.octokit = {};
}

pkg.octokit["openapi-version"] = process.env.OCTOKIT_OPENAPI_VERSION.replace(
  /^v/,
  ""
);

writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
