# Boostsecurity Scanner Registry

## Supported Scanners

### [Brakeman](scanners/boostsecurityio/brakeman)

### [Native](scanners/boostsecurityio/native-scanner)

### [Semgrep](scanners/boostsecurityio/semgrep/README.md)

### [Snyk](scanners/boostsecurityio/snyk-test/README.md)

### [Trivy](scanners/boostsecurityio/trivy-image)

### [Trivy-SBOM](scanners/boostsecurityio/trivy-sbom)

### [CodeQL](scanners/boostsecurityio/codeql)

### [GitLeaks](scanners/boostsecurityio/gitleaks)

## Scanner Testing

The registry includes automated testing for scanners. When a scanner is modified in a pull request, tests are automatically run across multiple CI/CD providers.

### Overview

- **Test Definition**: Each scanner can define tests in a `tests.yaml` file
- **Automatic Detection**: Modified scanners are detected and tested on PR
- **Multi-Provider**: Tests run on GitHub Actions, GitLab CI, Azure DevOps, and Bitbucket

### Documentation

- [Setting Up Tests](docs/setup-tests.md) - How to write tests for your scanner
- [Authentication Strategy](docs/authentication-strategy.md) - OAuth2/OIDC token architecture

#### Test Runner Setup (per CI/CD provider)

- [GitHub Actions](docs/setup-github.md)
- [GitLab CI](docs/setup-gitlab.md)
- [Azure DevOps](docs/setup-azure-devops.md)
- [Bitbucket Pipelines](docs/setup-bitbucket.md)
