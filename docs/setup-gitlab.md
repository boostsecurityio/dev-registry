# GitLab Test Runner Setup

## 1. Create Test Runner Repository

1. Create a new project named `scan-test-runner-gitlab-ci` in your GitLab group
2. Add the pipeline configuration at `.gitlab-ci.yml`
3. Ensure CI/CD pipelines are enabled for the project

---

## 2. Create OAuth2 Application

1. Navigate to your group settings:
   **Group → Settings → Applications**

   Or for self-hosted: `https://{GITLAB_HOST}/groups/{GROUP}/-/settings/applications`

2. Click **Add new application**

3. Configure the application:

   | Field            | Value                                                |
   |------------------|------------------------------------------------------|
   | **Name**         | `BoostSecurity.io Scan Test Runner`                  |
   | **Redirect URI** | `http://localhost` (not used for client credentials) |
   | **Confidential** | ✅ Checked                                            |
   | **Scopes**       | ✅ `api`                                              |

4. Click **Save application**

5. Note the **Application ID** and **Secret** - the secret is only shown once!

---

## 3. Configure Secrets on Scanner Registry Repository

Navigate to the scanner registry repository (GitHub):
**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name                              | Value                      |
|------------------------------------------|----------------------------|
| `BOOST_SCAN_RUNNER_GITLAB_CLIENT_ID`     | Application ID from step 2 |
| `BOOST_SCAN_RUNNER_GITLAB_CLIENT_SECRET` | Secret from step 2         |

---

## 4. Usage in GitHub Actions Workflow

```yaml
- name: Generate GitLab OAuth Token
  id: gitlab-token
  run: |
    response=$(curl -s -X POST "https://gitlab.com/oauth/token" \
      -d "grant_type=client_credentials" \
      -d "client_id=${{ secrets.BOOST_SCAN_RUNNER_GITLAB_CLIENT_ID }}" \
      -d "client_secret=${{ secrets.BOOST_SCAN_RUNNER_GITLAB_CLIENT_SECRET }}")

    token=$(echo "$response" | jq -r '.access_token')
    echo "token=$token" >> $GITHUB_OUTPUT
    echo "::add-mask::$token"

- name: Run test-action
  ...
```

---

## 5. Token Details

| Property     | Value                                            |
|--------------|--------------------------------------------------|
| **Lifetime** | 2 hours                                          |
| **Refresh**  | New token generated per workflow run             |
| **Scope**    | `api` (required for pipeline trigger and status) |

---

## References

- [GitLab OAuth2 Provider](https://docs.gitlab.com/ee/integration/oauth_provider.html)
- [GitLab OAuth2 API](https://docs.gitlab.com/ee/api/oauth2.html#client-credentials-flow)
- [GitLab Pipelines API](https://docs.gitlab.com/ee/api/pipelines.html)
