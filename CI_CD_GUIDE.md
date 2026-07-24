# CI/CD Pipeline Guide

This project leverages **GitHub Actions** for Continuous Integration and Continuous Deployment preparation.

## CI Workflow (`.github/workflows/ci.yml`)
Triggers on: `push` or `pull_request` to `main`.
1. **Backend Verification:** Installs Python dependencies, executes `python -m py_compile`, and builds the Docker container to verify the `Dockerfile` integrity.
2. **Flutter Verification:** Runs `flutter analyze` to enforce Dart linting rules and static analysis.

## CD Workflow (`.github/workflows/cd.yml`)
Triggers on: `workflow_dispatch` (Manual trigger).
1. Logs into Azure Container Registry (ACR).
2. Builds and tags the Docker image with the Git SHA.
3. Pushes to ACR.
4. Pauses for manual AKS `kubectl apply` rollout.

*Requires GitHub Secrets: `ACR_LOGIN_SERVER`, `ACR_USERNAME`, `ACR_PASSWORD`.*
