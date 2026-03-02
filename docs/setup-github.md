# GitHub Test Runner Setup

## 1. Create Test Runner Repository

1. Create a new repository named `scan-test-runner-gitbub-actions` in your organization
2. Add the workflow file at `.github/workflows/test-scanner.yml`
3. Ensure GitHub Actions is enabled for the repository

---

## 2. Create GitHub App

1. Navigate to your organization settings:
   **Organization → Settings → Developer settings → GitHub Apps → New GitHub App**

   Or use this link: `https://github.com/organizations/{ORG}/settings/apps/new`

2. Configure the GitHub App:

   | Field               | Value                               |
   |---------------------|-------------------------------------|
   | **GitHub App name** | `BoostSecurity.io Scan Test Runner` |
   | **Homepage URL**    | https://boostsecurity.io/           |
   | **Webhook**         | Uncheck "Active" (not needed)       |

3. Set **Repository permissions**:

   | Permission   | Access         |
   |--------------|----------------|
   | **Actions**  | Read and write |
   | **Contents** | Read-only      |

4. Set **Where can this GitHub App be installed?**:
   - Select "Only on this account"

5. Click **Create GitHub App**

6. Note the **App ID** (displayed at the top of the app settings page)

---

## 3. Generate Private Key

1. On the GitHub App settings page, scroll to **Private keys**
2. Click **Generate a private key**
3. A `.pem` file will be downloaded - keep this secure

---

## 4. Install the App

1. On the GitHub App settings page, click **Install App** in the left sidebar
2. Select your organization
3. Choose **Only select repositories**
4. Select `test-runner-github`
5. Click **Install**

---

## 5. Configure Secrets on Scanner Registry Repository

Navigate to the scanner registry repository:
**Settings → Secrets and variables → Actions → New repository secret**

| Secret Name                                 | Value                                   |
|---------------------------------------------|-----------------------------------------|
| `BOOST_SCAN_RUNNER_GITHUB_APP_ID`           | The App ID from step 2                  |
| `BOOST_SCAN_RUNNER_GITHUB_APP_PRIVATE_KEY`  | Contents of the `.pem` file from step 3 |

---

## 6. Usage in GitHub Actions Workflow

```yaml
- name: Generate GitHub App Token
  id: github-token
  uses: actions/create-github-app-token@v1
  with:
    app-id: ${{ secrets.GH_APP_ID }}
    private-key: ${{ secrets.GH_APP_PRIVATE_KEY }}
    owner: your-org
    repositories: test-runner-github

- name: Run test-action
  ...
```

---

## References

- [Creating a GitHub App](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app)
- [Authenticating as a GitHub App](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/about-authentication-with-a-github-app)
- [actions/create-github-app-token](https://github.com/actions/create-github-app-token)
