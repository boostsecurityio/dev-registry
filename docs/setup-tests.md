# Setting Up Scanner Tests

This guide explains how to write tests for scanners in the registry.

## Overview

Scanner tests are defined in a `tests.yaml` file within each scanner directory. When a scanner is modified in a pull request, the test system automatically detects the changes and runs the associated tests across configured CI/CD providers.

## Test Definition Format

Create a `tests.yaml` file in your scanner directory (e.g., `scanners/org/scanner-name/tests.yaml`):

```yaml
version: "1.0"
tests:
  - name: "Smoke test - source code"
    type: "source-code"
    source:
      url: "https://github.com/OWASP/NodeGoat.git"
      ref: "main"

  - name: "Container image scan"
    type: "container-image"
    source:
      url: "https://github.com/example/docker-app.git"
      ref: "v1.0"
    scan_paths:
      - "app"
      - "api"
```

## Fields Reference

| Field                | Required | Description                                |
|----------------------|----------|--------------------------------------------|
| `version`            | Yes      | Schema version (currently "1.0")           |
| `tests`              | Yes      | List of test specifications                |
| `tests[].name`       | Yes      | Human-readable test name                   |
| `tests[].type`       | Yes      | Either `source-code` or `container-image`  |
| `tests[].source.url` | Yes      | Git repository URL (HTTPS)                 |
| `tests[].source.ref` | Yes      | Git reference (branch, tag, or commit SHA) |
| `tests[].scan_paths` | No       | Paths to scan (default: `["."]`)           |
| `tests[].timeout`    | No       | Test timeout (default: `5m`)               |

## Test Types

### Source Code (`source-code`)

Tests that scan source code repositories. The scanner will clone the specified repository and run against the source files.

```yaml
- name: "Python project scan"
  type: "source-code"
  source:
    url: "https://github.com/example/python-app.git"
    ref: "main"
```

### Container Image (`container-image`)

Tests that scan container images. The repository should contain a Dockerfile or container definition.

```yaml
- name: "Docker image scan"
  type: "container-image"
  source:
    url: "https://github.com/example/docker-app.git"
    ref: "v1.0"
```

## Multiple Scan Paths

Use `scan_paths` to test multiple directories within a repository. Each path creates a separate test execution, enabling parallel testing:

```yaml
- name: "Monorepo scan"
  type: "source-code"
  source:
    url: "https://github.com/example/monorepo.git"
    ref: "main"
  scan_paths:
    - "services/api"
    - "services/web"
    - "libs/common"
```

## Best Practices

1. **Use stable references**: Prefer tags or commit SHAs over branches for reproducible tests
2. **Choose representative targets**: Select repositories that exercise your scanner's capabilities
3. **Keep tests fast**: Use smaller repositories when possible to reduce test time
4. **Test edge cases**: Include tests for both positive cases (findings expected) and negative cases (clean code)

## How Detection Works

The test system:

1. Compares the PR branch against the base branch to find changed files
2. Extracts scanner identifiers from paths like `scanners/org/scanner/file.yaml`
3. Filters to only scanners that have a `tests.yaml` file
4. Runs tests for each modified scanner across all configured CI/CD providers

## Example

A complete `tests.yaml` for a security scanner:

```yaml
version: "1.0"
tests:
  - name: "OWASP NodeGoat - Known vulnerabilities"
    type: "source-code"
    source:
      url: "https://github.com/OWASP/NodeGoat.git"
      ref: "main"

  - name: "OWASP WebGoat - Java vulnerabilities"
    type: "source-code"
    source:
      url: "https://github.com/WebGoat/WebGoat.git"
      ref: "v2023.8"
    timeout: "10m"

  - name: "Clean project - No findings expected"
    type: "source-code"
    source:
      url: "https://github.com/example/clean-project.git"
      ref: "v1.0.0"
```
