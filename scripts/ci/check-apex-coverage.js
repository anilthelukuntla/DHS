const fs = require('fs');

const resultPath = process.argv[2] || 'deploy-result.json';
const threshold = Number(process.argv[3] || 75);

if (!fs.existsSync(resultPath)) {
    console.error(`Salesforce deploy result file not found: ${resultPath}`);
    process.exit(1);
}

const payload = JSON.parse(fs.readFileSync(resultPath, 'utf8'));
const result = payload.result || payload;
const testResult = result.details?.runTestResult || result.runTestResult || result.testResult;

const normalizePct = (value) => {
    if (value === undefined || value === null || value === '') {
        return null;
    }
    if (typeof value === 'string' && value.includes('%')) {
        return Number(value.replace('%', ''));
    }
    return Number(value);
};

let coveragePct = normalizePct(testResult?.codeCoveragePercent);
coveragePct ??= normalizePct(testResult?.apexTestRunResult?.codeCoveragePercent);
coveragePct ??= normalizePct(result.coverage?.coveragePercent);

if ((coveragePct === null || Number.isNaN(coveragePct)) && Array.isArray(testResult?.codeCoverage)) {
    const totals = testResult.codeCoverage.reduce(
        (acc, item) => {
            acc.covered += Number(item.numLocations || item.numLocationsCovered || 0);
            acc.uncovered += Number(item.numLocationsNotCovered || 0);
            return acc;
        },
        { covered: 0, uncovered: 0 }
    );
    const totalLines = totals.covered + totals.uncovered;
    coveragePct = totalLines ? Number(((totals.covered / totalLines) * 100).toFixed(2)) : null;
}

if (coveragePct === null || Number.isNaN(coveragePct)) {
    console.error('Unable to determine Apex coverage from Salesforce deploy validation result.');
    console.error('Keep deploy-result.json as a workflow artifact and inspect the runTestResult payload.');
    process.exit(1);
}

if (coveragePct < threshold) {
    console.error(`Apex coverage gate failed: ${coveragePct}% < ${threshold}%.`);
    process.exit(1);
}

console.log(`Apex coverage gate passed: ${coveragePct}% >= ${threshold}%.`);
