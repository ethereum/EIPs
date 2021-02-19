import { getInput, setOutput } from "@actions/core";
import { getOctokit } from "@actions/github";

const test = async (Github: any) => {
    console.log(await Github.users.getByUsername({ username: "alita-moore"}))
  }  

export const main = () => {
    // `who-to-greet` input defined in action metadata file
    const nameToGreet = getInput("who-to-greet");
    console.log(`Hello ${nameToGreet}!`);
    const token = process.env.GITHUB_TOKEN;
    const Github = getOctokit(token);
    const time = new Date().toTimeString();
    setOutput("time", time);
    // Get the JSON webhook payload for the event that triggered the workflow
    // const payload = JSON.stringify(context.payload, undefined, 2);
    // console.log(`The event payload: ${payload}`);

    Github.log.info("testing1");
    Github.log.debug("testing2");
    test(Github);
}
