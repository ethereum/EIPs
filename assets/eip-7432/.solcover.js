module.exports = {
  skipFiles: ["mocks"],
  mocha: {
    grep: "@skip-on-coverage",
    invert: true,
  },
};
