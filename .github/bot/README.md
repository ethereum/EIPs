# EIP Linting Bot

This Github Actions integrated bot lints EIPs and provides feedback for authors, its goal is to catch simple problems and merge simple changes automatically.
# Usage

# Contributing
I won't fault you for making mistakes with these, but they should be considered when reviewing a PR

## Development Enviornment Setup

### Requirements
1) node package manager (npm)
2) Github Token 
3) Forked Repo
4) node version manager (nvm)

### Quick Start
1) Download your forked `EIPS` repo
2) Create a [Github Token](/creating-a-personal-access-token)
3) Create a PR in your forked repo doing anything, I recommend just editing a couple lines in an already existing EIPs
4) Create a .env variable in the root dir with the following information defined:

```
GITHUB_TOKEN = <YOUR GITHUB TOKEN>
NODE_ENV = development

BASE_SHA = <base sha of the PR>
HEAD_SHA = <head sha of the PR>
REPO_OWNER_NAME = <your login>
REPO_NAME = EIPs
GITHUB_REPOSITORY = <your login>/EIPs
```
5) `npm run it`

### npm scripts

This repo uses ncc; ncc compiles the code into a single pure js file, and that makes it easier for github to execute. But it also means we have to both build the output and commit it. So, when developing do..

```
npm run watch // re-builds after each save
npm run build // re-builds
npm run it // runs the action using a basic development
```
### Troubleshooting
- <i>I make changes but nothing changes when I `npm run it`</i>
  - This repo requires that the changes be compiled in a pure js distribution `dist/index.js`
  - Try running `npm run build` and see if that helps
  - If it does, make sure to keep `npm run watch` running in the background while you make changes, it'll re-compile whenever changes are made and make life easier
- <i>When I run I'm getting unexplainable errors with my github requests.</i>
  - Github limits the number requests from a given IP, this may be avoidable if you only use the `octokit` but a VPN also works just fine

## Important Context
#### || There are **two GLOBAL** variables ||
These are two globl variables `ERRORS` & `EIPs`, and you should be careful about accessing them. Only do so under certain circumstances

- `src/main.ts/ERRORS` (for non-critical errors)
  - When **TO** touch `ERRORS`...
    - Filename is formatted incorrectly
    - The eip changed status from draft -> last call
  - How to access
    - `ERRORS.push("File EIPS/foo.md is not an EIP")`

ERRORS is global for the sake of convenience, but its use in an asynchronous enviornment causes order of errors pushed to be non-guaranteed. At the time of writing this, it makes more sense to just ignore it, but it's worth keeping in mind.

## Code Style Guidelines (in no particular order)
This repo is a living repo, and it will grow with the EIP drafting and editing process. As such, it's important to maintain code quality for the sake of readability and maintanability sake. Also, this is open-source and will benefit from strict code quality guidelines. The guidelines are, of course, mutable but please thoroughly explain each proposed rule change.

1) Define every type (including octokit)
2) Make clean and clear error messages
3) Keep methods shallow where feasible
4) Avoid Abstraction
5) Always use [enums](https://www.sohamkamani.com/javascript/enums/) when defining restricted string types
6) Don't use `export default ...`
## Explanations of Style Guidenlines
A couple things to keep in mind if you end up making changes to this

#### 1. <ins>Define every type</ins>
Define every type, no `any` types. The time it takes to define a type now will save you or someone else later a lot of time. If you make assumptions about types, protect those assumptions (throw exception if they are false).

Sometimes [Octokit types](https://www.npmjs.com/package/@octokit/types) can be difficult to index, but it's important that whenever possible the types are defined and assumptions protected.

#### 2. <ins>Make clean and clear error messages</ins>
This bot has a single goal: catch simple mistakes automatically and save the editors time. Unclear errors means that it is more likely that 

#### 3. <ins>Keep logic shallow where feasible</ins>
Maintaining code readability is very important in this repo; but sometimes it becomes all too tempting to obfuscate all logic into sub-methods to make the high-level actions more clear. While I generally think this is a good thing, keep in mind that somtimes obfuscation makes things more confusing.
```javascript
\\ DONT DO THIS
const foo = () => bar() ? "bar" : "foo" // layer 1
const bar = () => baz() ? true : false  // layer 2
const baz = () => true                  // layer 3

\\ DO THIS
const foo = () => {                
  const bar = baz() ? true : false      // layer 1
  return bar ? "bar" : "foo"            // layer 1
}
const baz = () => true                  // layer 2
```
#### 4. <ins>Avoid Abstraction</ins>
Only abstract if necessary, keep things in one file where applicable; other examples of okay abstraction are types, regex, and methods used more than 3 times. Otherwise, it's often cleaner to just re-write things.
```javascript
// DON'T DO THIS
** src/lib.ts **
export const baz = () => "baz"

** src/foo.ts **
import { baz } from "./lib"
export const foo = () => baz();

** src/bar.ts **
import { baz } from "./lib"
export const bar = () => baz();

// DO THIS
** src/foo.ts **
const baz = () => "baz"
export const foo = () => baz();

** src/bar.ts **
const baz = () => "baz"
export const bar = () => baz();
```
#### 5. <ins>Always use enum when defining restricted string types</ins>
In short, enums make code easier to read, trace, and maintain. 

But here's a brief info if you haven't worked with them before

```typescript
enum EnumFoo {
  bar = "BAR",
  baz = "BAZ"
}
type Foo = "BAR" | "BAZ"
```
Inline declaraion is maintained
```typescript
const foo: EnumFoo
const bar: Foo
// foo and bar both must be either "BAR" or "BAZ"
```
Use case is slightly different
```typescript
const foo: EnumFoo = EnumFoo.baz // you can't directly assign "BAZ"
const bar: Foo = "BAZ"
```
But comparisons are maintained
```typescript
// taking variables from above
("BAZ" === foo) === ("BAZ" === bar)
&&
("BAZ" === EnumFoo.baz) === ("BAZ" === "BAZ")
```
In addition to the above use case and string eradication it centralizes the strings to be matched so they can be easily changed. So, making life much easier if you wanted to change the names of statuses on an EIP.

# Contributors
- @alita-moore
