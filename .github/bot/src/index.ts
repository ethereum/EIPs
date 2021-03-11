require('module-alias/register')
import { main } from "./main";
import { __MAIN__ } from "./utils";

const isDebug = process.env.NODE_ENV === "development" || process.env.NODE_ENV === "test";
isDebug ? __MAIN__() : main();
