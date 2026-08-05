const fs = require('fs');
const path = require('path');

const threshold = Number(process.argv[2] || 80);
const summaryPath = path.join(process.cwd(), 'coverage', 'coverage-summary.json');

if (!fs.existsSync(summaryPath)) {
    console.error(`Coverage summary not found at ${summaryPath}. Run Jest with --coverage first.`);
    process.exit(1);
}

const summary = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
const failures = [];

const assertMetric = (label, metric, pct) => {
    if (pct < threshold) {
        failures.push(`${label} ${metric} coverage is ${pct}% < ${threshold}%`);
    }
};

Object.entries(summary)
    .filter(([file]) => file !== 'total')
    .filter(([file]) => file.replace(/\\/g, '/').includes('/force-app/main/default/lwc/'))
    .filter(([file]) => !file.replace(/\\/g, '/').includes('/__tests__/'))
    .forEach(([file, coverage]) => {
        const relative = path.relative(process.cwd(), file);
        assertMetric(relative, 'statement', coverage.statements.pct);
        assertMetric(relative, 'line', coverage.lines.pct);
        assertMetric(relative, 'function', coverage.functions.pct);
    });

assertMetric('All LWC files', 'statement', summary.total.statements.pct);
assertMetric('All LWC files', 'line', summary.total.lines.pct);
assertMetric('All LWC files', 'function', summary.total.functions.pct);

if (failures.length) {
    console.error('LWC coverage gate failed:');
    failures.forEach((failure) => console.error(`- ${failure}`));
    process.exit(1);
}

console.log(`LWC Jest coverage gate passed at ${threshold}% minimum.`);
