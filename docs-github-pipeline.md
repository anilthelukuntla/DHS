# Intel GitHub Pipeline Setup

## Branch Flow

1. Feature branches open PRs into `INTELUAT`.
2. PRs into `INTELUAT` must pass:
   - LWC ESLint
   - LWC Jest coverage gate, minimum 80%
   - Apex PMD through Salesforce Code Analyzer
   - Apex deployment validation and Apex coverage, minimum 75%, only when Apex classes/triggers changed
   - Required reviewer approval
3. Merge into `INTELUAT` deploys to the INTELUAT Salesforce org.
4. After UAT approval, open a PR from `INTELUAT` into `main`.
5. Merge into `main` deploys to production after the GitHub `production` environment approval gate.

## Required GitHub Secrets

Add these repository or environment secrets.

### INTELUAT

- `SF_UAT_CLIENT_ID`
- `SF_UAT_USERNAME`
- `SF_UAT_INSTANCE_URL`, usually `https://test.salesforce.com`
- `SF_UAT_JWT_KEY`, the private key text for the Salesforce connected app JWT flow

### Production

- `SF_PROD_CLIENT_ID`
- `SF_PROD_USERNAME`
- `SF_PROD_INSTANCE_URL`, usually `https://login.salesforce.com`
- `SF_PROD_JWT_KEY`, the private key text for the Salesforce connected app JWT flow

Use Salesforce JWT auth for CI. Do not store Salesforce passwords, GitHub passwords, certificates, or private keys in the repository.

## Required Branch Protection / Rulesets

Create rules for `INTELUAT` and `main`:

- Require pull request before merging.
- Require at least 1 approval. Use 2 approvals for `main` if possible.
- Require review from Code Owners.
- Dismiss stale approvals when new commits are pushed.
- Require conversation resolution.
- Require status checks before merging:
  - `LWC ESLint, Jest Coverage, Apex PMD`
  - `Apex Validation and Coverage`
- Require branches to be up to date before merging.
- Block force pushes.
- Block branch deletion.
- Restrict who can push directly to `INTELUAT` and `main`.

Create GitHub environments:

- `INTELUAT`, optional reviewers if you want a deployment approval before UAT deploy.
- `production`, required reviewers enabled. This is the production release approval gate.

## Repo Creation

This machine does not currently have GitHub CLI authenticated. After logging in securely, create the private repo without pushing code:

```bash
gh auth login
gh repo create Intel --private
```

Then initialize and connect this local project:

```bash
git init
git branch -M INTELUAT
git remote add origin https://github.com/<owner>/Intel.git
```

Push only when ready:

```bash
git add .
git commit -m "Set up CI/CD pipeline"
git push -u origin INTELUAT
```

## Local Commands

Run LWC ESLint:

```bash
npm run lint:lwc
```

Run Jest coverage and enforce 80%:

```bash
npm run test:unit:coverage:ci
npm run coverage:lwc:check
```

Run Apex coverage gate after a Salesforce deploy validation result exists:

```bash
node scripts/ci/check-apex-coverage.js deploy-result.json 75
```

## References

- Salesforce recommends JWT auth for CI environments that cannot support interactive login.
- The workflow uses the official `forcedotcom/run-code-analyzer@v2` action, which is based on Salesforce Code Analyzer v5 and supports PMD.
