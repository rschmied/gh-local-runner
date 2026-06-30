# gh-runner

A small GitHub Actions self-hosted runner container that triggers a Jenkins job for every push or pull request.

## Quick setup

1. **In GitHub**: add the workflow secrets `JENKINS_URL`, `JENKINS_USER`, and `JENKINS_TOKEN` in the repository or organization settings.
2. **On the machine that runs the container**: export `GH_OWNER`, `GH_REPO`, `GH_TOKEN`, and `GH_PAT` before starting the runner.
3. **On the machine that runs the container**: build the image and start it with `./run.sh`.

See the sections below for the exact commands and UI paths for both GitHub and the local host.

## What this repo does

The workflow in `.github/workflows/jenkins-trigger.yml` runs on a self-hosted runner. That runner is provided by the Docker image in this repository.

When the workflow runs, it sends a `curl` request to Jenkins:

```text
${JENKINS_URL}/job/${repository_name}/build?delay=0sec
```

with HTTP Basic Auth using the Jenkins user/token you configure in GitHub Secrets.

## Repo layout

- `Dockerfile` - builds a GitHub Actions runner image
- `entrypoint.sh` - registers the runner with GitHub and keeps it running
- `run.sh` - helper to start the runner container locally
- `.github/workflows/jenkins-trigger.yml` - workflow that triggers Jenkins
- `jenkins-dummy.py` - simple local HTTP server for testing webhook-style requests

## Prerequisites

- Docker
- A GitHub repository where you can set Actions secrets
- A Jenkins server/job to trigger

## GitHub Actions secrets for the workflow

The workflow in `.github/workflows/jenkins-trigger.yml` expects these secrets:

| Secret | Purpose |
| --- | --- |
| `JENKINS_URL` | Base URL of your Jenkins server, for example `https://jenkins.example.com` |
| `JENKINS_USER` | Jenkins username used for authentication |
| `JENKINS_TOKEN` | Jenkins API token or password for that user |

You can store these at the **repository** level or the **organization** level.

### Repository-level secrets

Use repository secrets if only this repo should trigger Jenkins.

**GitHub UI:**

`Repository -> Settings -> Secrets and variables -> Actions -> New repository secret`

**GitHub CLI:**

```bash
gh secret set JENKINS_URL --repo OWNER/REPO --body "https://jenkins.example.com"
gh secret set JENKINS_USER --repo OWNER/REPO --body "jenkins-bot"
gh secret set JENKINS_TOKEN --repo OWNER/REPO --body "your-jenkins-api-token"
```

### Organization-level secrets

Use organization secrets if multiple repositories should share the same Jenkins credentials.

**GitHub UI:**

`Organization -> Settings -> Secrets and variables -> Actions -> New organization secret`

**GitHub CLI:**

```bash
# organization secrets require admin:org on the gh CLI
# gh auth login --scopes admin:org

gh secret set JENKINS_URL --org ORG_NAME --repos OWNER/REPO --body "https://jenkins.example.com"
gh secret set JENKINS_USER --org ORG_NAME --repos OWNER/REPO --body "jenkins-bot"
gh secret set JENKINS_TOKEN --org ORG_NAME --repos OWNER/REPO --body "your-jenkins-api-token"
```

If you use organization secrets, make sure the secret policy allows access to this repository.

These values are referenced in the workflow as `secrets.JENKINS_URL`, `secrets.JENKINS_USER`, and `secrets.JENKINS_TOKEN`.

## Local runner setup

The runner container is configured through these local environment variables when you start it:

| Variable | Purpose |
| --- | --- |
| `GH_OWNER` | GitHub user or organization that owns the repository |
| `GH_REPO` | Repository name the runner should register against |
| `GH_TOKEN` | Temporary GitHub Actions runner registration token |
| `GH_PAT` | GitHub personal access token used only to fetch a fresh runner removal token during shutdown |

Important:

- `GH_TOKEN` is **not** your GitHub personal access token.
- It is the short-lived registration token you copy from GitHub when creating a self-hosted runner.
- `GH_PAT` is used only for shutdown cleanup so the runner can request a fresh removal token from GitHub.
- The runner is registered with the name `internal-jenkins-bridge` and the label `jenkins-trigger`.

### `GH_PAT` permissions

Because the container removes the runner on shutdown, `GH_PAT` needs permission to call GitHub's repository self-hosted runner remove-token endpoint for this repo.

Use one of these:

- **Classic PAT:** `repo` scope for private repositories, or `public_repo` for public repositories
- **Fine-grained PAT:** limit the token to this repository and grant **Repository permissions -> Administration -> Read and write**

If the token does not have enough permission, the container will start, but shutdown cleanup will leave a stale runner registration behind.

### Start the runner locally

1. Build the image:

   ```bash
   docker build -t github-runner .
   ```

2. Export the runner registration values:

   ```bash
   export GH_OWNER=your-org-or-user
   export GH_REPO=your-repo
   export GH_TOKEN=the-temporary-runner-registration-token
   export GH_PAT=your-github-pat
   ```

3. Start the container:

   ```bash
   ./run.sh
   ```

The helper adds `host.docker.internal` so the runner can reach services running on your host machine.

### Firewall / host networking

If your host uses UFW and the runner needs to reach a service on the host, you may need to allow traffic from the Docker bridge interface. For example, to reach Jenkins on port 8080:

```bash
# Check if UFW is active
sudo ufw status

# If it is active, explicitly allow traffic from the docker interface:
sudo ufw allow in on docker0 to any port 8080 proto tcp
sudo ufw reload
```

If your Docker bridge uses a different interface name or your service listens on a different port, adjust the command accordingly.

## Jenkins job naming

The workflow currently assumes the Jenkins job name matches the GitHub repository name:

```text
${JENKINS_URL}/job/${REPO_NAME}/build?delay=0sec
```

If your Jenkins job uses a different name or folder structure, update `.github/workflows/jenkins-trigger.yml` accordingly.

## Optional local test server

`jenkins-dummy.py` is a tiny aiohttp server that prints incoming POST requests. It can be useful while developing the workflow.

For example:

```bash
python jenkins-dummy.py
```

Then set `JENKINS_URL` to something like `http://host.docker.internal:8080`.

## Notes

- The workflow runs on `push` and `pull_request`.
- Jenkins credentials should be stored as GitHub Secrets, not hard-coded in the workflow.
- If you change the runner label or name in `entrypoint.sh`, update the workflow `runs-on` value to match.
