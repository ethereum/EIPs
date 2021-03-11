import { setEnvAsContext } from "src/utils";

const github = jest.createMockFromModule("@actions/github");

describe("jest should run", () => {
  
  it("runs", () => {
    setEnvAsContext({})
  })
})

export {}