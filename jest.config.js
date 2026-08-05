const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        ...jestConfig.moduleNameMapper,
        '^force-app/(.*)$': '<rootDir>/force-app/$1',
        '^lightning/select$':
            '<rootDir>/force-app/test/jest-mocks/lightning/select/select',
        '^lightning/modal$':
            '<rootDir>/force-app/test/jest-mocks/lightning/modal/modal'
    },
    collectCoverageFrom: [
        'force-app/main/default/lwc/**/*.js',
        '!force-app/main/default/lwc/**/__tests__/**'
    ],
    coverageReporters: ['json', 'json-summary', 'lcov', 'clover', 'text'],
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver']
};
