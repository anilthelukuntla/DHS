# INTELDEPLOYHUB Client Credentials Setup

Use a Salesforce Connected App with OAuth 2.0 Client Credentials flow for GitHub Actions deployments.

## Salesforce Setup

1. In `INTELDEPLOYHUB`, create or update a Connected App.
2. Enable OAuth settings.
3. Enable Client Credentials flow.
4. Add OAuth scope `api`.
5. Save the Connected App.
6. In **Manage Connected Apps**, edit the app policies and set the Client Credentials flow **Run As** user to the deployment integration user.
7. Copy the connected app consumer key and consumer secret.

## GitHub Secrets

Add these repository secrets in `ISNCORP/Intel`:

```text
SF_INTELDEPLOYHUB_CLIENT_ID
SF_INTELDEPLOYHUB_CLIENT_SECRET
SF_INTELDEPLOYHUB_INSTANCE_URL
```

Use this instance URL:

```text
https://isn-foresite--deployhub.sandbox.my.salesforce.com
```

The GitHub Actions workflow exchanges the client credentials for a Salesforce access token, then runs:

```bash
sf org login access-token --instance-url "$SF_INTELDEPLOYHUB_INSTANCE_URL" --no-prompt --alias INTELDEPLOYHUB
```
