# CI/CD Test Runner Authentication Strategy

## Executive Summary

Migration from long-lived user tokens to short-lived OAuth2/OIDC tokens across all CI/CD platforms for the scanner registry test orchestration system.

---

## Authentication Solution

| Platform         | Auth Method                          | Token Lifetime        | User-Independent |
|------------------|--------------------------------------|-----------------------|------------------|
| **GitHub**       | GitHub App                           | 1 hour                | ✅                |
| **GitLab**       | Trigger Token + Read Token (2-token) | Trigger: ∞, Read: 1yr | ⚠️ Read token    |
| **Azure DevOps** | OIDC (Federated Identity)            | ~1 hour               | ✅                |
| **Bitbucket**    | OAuth2 Consumer                      | 2 hours               | ✅                |

### Architecture Flow

```
Scanner Registry PR Created
         ↓
GitHub Actions Workflow Triggered
         ↓
┌────────────────────────────────────┐
│  Token Generation (in GH Actions)  │
│  - GitHub: Official Action         │
│  - GitLab: Stored tokens (2-token) │
│  - Azure: OIDC (no secrets)        │
│  - Bitbucket: OAuth2 API call      │
└────────────────────────────────────┘
         ↓
Short-lived tokens (1-2 hours)
         ↓
Passed to test-action CLI
         ↓
Trigger test pipelines on each platform
         ↓
Tokens expire automatically
```

### GitLab Two-Token Approach

GitLab does not support OAuth2 client credentials flow. We use two purpose-specific tokens:

| Token                      | Purpose           | Scope                           |
|----------------------------|-------------------|---------------------------------|
| **Pipeline Trigger Token** | Trigger pipelines | Can only trigger, no API access |
| **Project Access Token**   | Poll status       | `read_api` only, Guest role     |

This provides least-privilege access - neither token alone can both trigger and read.

### Key Security Improvements

- ✅ **Short-lived tokens** - Auto-expire in 1-2 hours (vs. indefinite)
- ✅ **No manual rotation** - Tokens generated fresh on each run
- ✅ **Application-based** - Not tied to user accounts
- ✅ **Principle of least privilege** - Minimal scopes (trigger pipelines + read status)
- ✅ **Secrets isolation** - Client credentials stored only in GitHub Actions, never in test-action
- ✅ **Zero secrets for Azure** - OIDC federated identity eliminates client secret storage entirely
- ✅ **Industry standard** - OAuth2/OIDC protocols used by all platforms

---

## Rejected Alternatives

**Managed Identities (Azure)** - Only works if test-action runs inside Azure infrastructure; not applicable for GitHub Actions execution.

**Service Principal with Client Secret (Azure)** - Requires storing `AZURE_CLIENT_SECRET` in GitHub Actions; OIDC federated identity is more secure as it eliminates secret storage entirely.

**Repository/Workspace Access Tokens (Bitbucket)** - Cannot trigger or read pipeline status; insufficient permissions for use case.

**OIDC for GitHub API** - OIDC is for external services authenticating to GitHub, not for GitHub Actions triggering other GitHub workflows; GitHub Apps are the correct solution.

**GitLab OAuth2 Client Credentials** - GitLab does not support OAuth2 client credentials flow for machine-to-machine authentication; two-token approach (trigger + read) provides equivalent security with least-privilege separation.

---

## Implementation Requirements

### One-Time Setup (per platform)

1. **GitHub**: Register GitHub App with `contents: read`, `actions: write` permissions
2. **GitLab**: Create Pipeline Trigger Token + Project Access Token (`read_api`, Guest role)
3. **Azure DevOps**: Register Microsoft Entra ID application, add federated credential for GitHub Actions OIDC, grant Build (Read & Execute) to Azure DevOps project
4. **Bitbucket**: Create OAuth2 Consumer with `pipeline`, `pipeline:write`, `repository` scopes

### Secrets Configuration

Store credentials in GitHub Actions repository secrets:
- `BOOST_SCAN_RUNNER_GITHUB_APP_ID`, `BOOST_SCAN_RUNNER_GITHUB_APP_PRIVATE_KEY`
- `BOOST_SCAN_RUNNER_GITLAB_TRIGGER_TOKEN`, `BOOST_SCAN_RUNNER_GITLAB_READ_TOKEN`
- `BOOST_SCAN_RUNNER_ADO_TENANT_ID`, `BOOST_SCAN_RUNNER_ADO_CLIENT_ID` (no client secret - uses OIDC)
- `BOOST_SCAN_RUNNER_BITBUCKET_CLIENT_ID`, `BOOST_SCAN_RUNNER_BITBUCKET_CLIENT_SECRET`

### Code Changes

- **GitHub Actions workflow**: Add token generation steps (GitHub App action, OAuth API calls, azure/login with OIDC)
- **GitHub Actions permissions**: Add `id-token: write` permission for Azure OIDC
- **test-action CLI**: Accept `--{platform}-token` arguments (GitLab: `--gitlab-trigger-token`, `--gitlab-read-token`)
- **Providers**: Use provided tokens directly instead of generating them

---

## Security Benefits Summary

| Metric          | Before          | After               | Improvement            |
|-----------------|-----------------|---------------------|------------------------|
| Token Lifetime  | Indefinite      | 1-2 hours           | **99%+ reduction**     |
| Manual Rotation | Required        | None                | **Zero maintenance**   |
| User Dependency | Yes (4 users)   | No (4 apps)         | **Zero bus factor**    |
| Token Scope     | Over-privileged | Minimal             | **Least privilege**    |
| Audit Trail     | User actions    | Application actions | **Better attribution** |

---

## Compliance & Standards

- ✅ **OAuth 2.0 / OpenID Connect** - Industry standard protocols (RFC 6749, RFC 7519)
- ✅ **Zero Trust** - Short-lived credentials, continuous verification
- ✅ **NIST SP 800-63B** - Authenticator assurance level via cryptographic proof
- ✅ **SOC 2 / ISO 27001** - Automated credential lifecycle management
