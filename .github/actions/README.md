# EIP Linting Bot

This bot scrapes EIPs and provides feedback for authors, it also can auto-merge changes if certain criteria are met

# Development

## Guidelines

A couple things to keep in mind if you end up making changes to this

1) Keep it simple and functional
2) Define every type
3) Try to log everything, this makes debugging easier and feedback more clear

## Tools
This repo uses ncc; ncc compiles the code into a single pure js file, and that makes it easier for github to execute. But it also means we have to both build the output and commit it. So, when developing do..

```
npm run watch // re-builds after each save
npm run build // re-builds
npm run it // runs the action using a basic development
```

You will also want to create a .env that looks similar to this:
```
GITHUB_TOKEN = <generate one and develope on a forked repo>
NODE_ENV = development

BASE_SHA = 0aac7ef5eee2290ed8fe05a6f05fe0f7b4a9e59d
HEAD_SHA = c09795eb23ebb5918d446ebafbd899fe84835f97
REPO_OWNER_NAME = alita-moore
REPO_NAME = EIPs
GITHUB_REPOSITORY = alita-moore/EIPs
```
Basically, the above simulates the basic inputs from a pull_request call.
# Contributors
- @alita-moore
