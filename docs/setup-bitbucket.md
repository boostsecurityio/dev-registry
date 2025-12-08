# Bitbucket Test Runner Setup

## 1. Create Test Runner Repository

1. Create a new repository named `scan-test-runner-bitbucket-pipelines` in your Bitbucket workspace
2. Add the pipeline configuration at `bitbucket-pipelines.yml`
3. Enable Pipelines: **Repository settings → Pipelines → Settings → Enable Pipelines**

---

## 2. Create OAuth2 Consumer

1. Navigate to your workspace settings:
   **Workspace → Settings → OAuth consumers → Add consumer**

   Direct link: `https://bitbucket.org/{WORKSPACE}/workspace/settings/api`

2. Configure the OAuth consumer:

   | Field                          | Value                                                |
   |--------------------------------|------------------------------------------------------|
   | **Name**                       | `BoostSecurity.io Scan Test Runner`                  |
   | **Callback URL**               | `http://localhost` (not used for client credentials) |
   | **This is a private consumer** | ✅ Checked                                            |

3. Set **Permissions**:

   | Permission       | Access |
   |------------------|--------|
   | **Repositories** | Read   |
   | **Pipelines**    | Read   |
   | **Pipelines**    | Write  |

4. Click **Save**

5. Note the **Key** (client ID) and **Secret** - the secret is only shown once!

---

## 3. Configure Secrets on Scanner Registry Repository

Navigate to the scanner registry repository (GitHub):
**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name                                 | Value              |
|---------------------------------------------|--------------------|
| `BOOST_SCAN_RUNNER_BITBUCKET_CLIENT_ID`     | Key from step 2    |
| `BOOST_SCAN_RUNNER_BITBUCKET_CLIENT_SECRET` | Secret from step 2 |


---

## 4. Usage in GitHub Actions Workflow

```yaml
- name: Generate Bitbucket OAuth Token
  id: bitbucket-token
  run: |
    response=$(curl -s -X POST \
      "https://bitbucket.org/site/oauth2/access_token" \
      -u "${{ secrets.BOOST_SCAN_RUNNER_BITBUCKET_CLIENT_ID }}:${{ secrets.BOOST_SCAN_RUNNER_BITBUCKET_CLIENT_SECRET }}" \
      -d "grant_type=client_credentials")

    token=$(echo "$response" | jq -r '.access_token')
    echo "token=$token" >> $GITHUB_OUTPUT
    echo "::add-mask::$token"

- name: Run test-action
  ...
```

---

## 5. Token Details

| Property     | Value                                      |
|--------------|--------------------------------------------|
| **Lifetime** | 2 hours                                    |
| **Refresh**  | New token generated per workflow run       |
| **Scopes**   | `repository`, `pipeline`, `pipeline:write` |

---

## 6. API Endpoints

| Operation               | Endpoint                                                                             |
|-------------------------|--------------------------------------------------------------------------------------|
| **Trigger Pipeline**    | `POST https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}/pipelines/`      |
| **Get Pipeline Status** | `GET https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}/pipelines/{uuid}` |

---

## References

- [Bitbucket OAuth2](https://support.atlassian.com/bitbucket-cloud/docs/use-oauth-on-bitbucket-cloud/)
- [OAuth2 Client Credentials Grant](https://support.atlassian.com/bitbucket-cloud/docs/use-oauth-on-bitbucket-cloud/#Client-credentials-Grant--4-LO-)
- [Bitbucket Pipelines API](https://developer.atlassian.com/cloud/bitbucket/rest/api-group-pipelines/)
