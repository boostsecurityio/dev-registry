# GitLab Test Runner Setup

GitLab does not support OAuth2 client credentials flow. Instead, we use a **two-token approach** for least-privilege access:

| Token                      | Purpose              | Permissions                  |
|----------------------------|----------------------|------------------------------|
| **Pipeline Trigger Token** | Trigger pipelines    | Trigger only (no API access) |
| **Project Access Token**   | Poll pipeline status | `read_api` scope, Guest role |

---

## 1. Create Test Runner Repository

1. Create a new project named `scan-test-runner-gitlab-ci` in your GitLab group
2. Add the pipeline configuration at `.gitlab-ci.yml`
3. Ensure CI/CD pipelines are enabled for the project

---

## 2. Create Pipeline Trigger Token

1. Navigate to your project:
   **Project → Settings → CI/CD → Pipeline trigger tokens**

   Or: `https://gitlab.com/{GROUP}/{PROJECT}/-/settings/ci_cd#js-pipeline-triggers`

2. Click **Add new token**

3. Enter a description: `Scanner Registry Test Orchestrator`

4. Click **Create pipeline trigger token**

5. Copy the **trigger token** - it's only shown once!

6. Ensure the ** CI/CD > Variables > Minimum role to use pipeline variables ** is set to **Developer** 

---

## 3. Create Project Access Token (for polling)

1. Navigate to your project:
   **Project → Settings → Access tokens**

   Or: `https://gitlab.com/{GROUP}/{PROJECT}/-/settings/access_tokens`

2. Click **Add new token**

3. Configure the token:

   | Field               | Value                                          |
      |---------------------|------------------------------------------------|
   | **Token name**      | `Scanner Registry Status Poller`               |
   | **Expiration date** | Set to 1 year (maximum), add rotation reminder |
   | **Role**            | **Guest** (minimal)                            |
   | **Scopes**          | ✅ `read_api` only                              |

4. Click **Create project access token**

5. Copy the **token** - it's only shown once!

---

## 4. Configure Secrets on Scanner Registry Repository

Navigate to the scanner registry repository (GitHub):
**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name                             | Value                              |
|-----------------------------------------|------------------------------------|
| `BOOST_SCAN_RUNNER_GITLAB_TRIGGER_TOKEN`    | Pipeline trigger token from step 2 |
| `BOOST_SCAN_RUNNER_GITLAB_READ_TOKEN` | Project access token from step 3   |

---

## 5. Usage in GitHub Actions Workflow

```yaml
- name: Run test-action
  run: |
    use "${{ secrets.BOOST_SCAN_RUNNER_GITLAB_TRIGGER_TOKEN }}" \
    use "${{ secrets.BOOST_SCAN_RUNNER_GITLAB_READ_TOKEN }}"
```

---

## 6. Token Details

| Token             | Lifetime      | Scope                  | Rotation                       |
|-------------------|---------------|------------------------|--------------------------------|
| **Trigger Token** | No expiration | Trigger pipelines only | Manual (revoke if compromised) |
| **Read Token**    | 1 year max    | `read_api` (read-only) | Annual rotation required       |

---

## 7. Security Notes

- **Trigger token** can only start pipelines - cannot read data or modify anything
- **Read token** has Guest role with `read_api` - cannot trigger or modify anything
- Neither token can access code, settings, or other projects
- Separation ensures compromise of one token limits blast radius

---

## References

- [Pipeline Trigger Tokens](https://docs.gitlab.com/ee/ci/triggers/)
- [Project Access Tokens](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html)
- [GitLab API Authentication](https://docs.gitlab.com/ee/api/rest/#authentication)
- [Pipelines API](https://docs.gitlab.com/ee/api/pipelines.html)
