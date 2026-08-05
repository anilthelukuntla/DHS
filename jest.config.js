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
        '!force-app/main/default/lwc/**/__tests__/**',
        '!force-app/main/default/lwc/dhsCaseFileUploader/**',
        '!force-app/main/default/lwc/dhsConfiguration/**',
        '!force-app/main/default/lwc/dhsDisplayCaseContacts/**',
        '!force-app/main/default/lwc/dhsDraggableDataTable/**',
        '!force-app/main/default/lwc/dhsMergeFieldsModal/**',
        '!force-app/main/default/lwc/draggableDataTable/**',
        '!force-app/main/default/lwc/lmsTrainingDetail/**',
        '!force-app/main/default/lwc/lmsTrainingViewer/**',
        '!force-app/main/default/lwc/mergeFieldsModal/**',
        '!force-app/main/default/lwc/rmsPortal/**',
        '!force-app/main/default/lwc/upsertReportExport/**'
    ],
    coverageReporters: ['json', 'json-summary', 'lcov', 'clover', 'text'],
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver']
};
