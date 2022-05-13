/** @type {import('ts-jest/dist/types').InitialOptionsTsJest} */
module.exports = {
    preset: 'ts-jest',
    testEnvironment: 'node',
    modulePathIgnorePatterns: ["<rootDir>/dist/"],
    projects: [
        '<rootDir>/packages/siwe/jest.config.js',
        '<rootDir>/packages/siwe-parser/jest.config.js'
    ]
};
