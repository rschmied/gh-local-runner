# gh-runner

A small GitHub Actions self-hosted runner container that triggers a Jenkins job for every push or pull request.

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

## Required GitHub repository secrets

The workflow expects these repository secrets to exist:

| Secret | Purpose |
| --- | --- |
| `JENKINS_URL` | Base URL of your Jenkins server, for example `https://jenkins.example.com` |
| `JENKINS_USER` | Jenkins username used for authentication |
| `JENKINS_TOKEN` | Jenkins API token or password for that user |

These are referenced in the workflow as `secrets.JENKINS_URL`, `secrets.JENKINS_USER`, and `secrets.JENKINS_TOKEN`.

### Set them with the GitHub CLI

```bash
gh secret set JENKINS_URL --body "https://jenkins.example.com" --repo OWNER/REPO
gh secret set JENKINS_USER --body "jenkins-bot" --repo OWNER/REPO
gh secret set JENKINS_TOKEN --body "your-jenkins-api-token" --repo OWNER/REPO
```

Replace `OWNER/REPO` with your repository name.

### Or set them in the GitHub UI

Go to:

`Repository -> Settings -> Secrets and variables -> Actions -> New repository secret`

Create the three secrets with the exact names above.

## Local runner setup

The runner container is configured through these local environment variables when you start it:

| Variable | Purpose |
| --- | --- |
| `GH_OWNER` | GitHub user or organization that owns the repository |
| `GH_REPO` | Repository name the runner should register against |
| `GH_TOKEN` | Temporary GitHub Actions runner registration token |

Important:

- `GH_TOKEN` is **not** your GitHub personal access token.
- It is the short-lived registration token you copy from GitHub when creating a self-hosted runner.
- The runner is registered with the name `internal-jenkins-bridge` and the label `jenkins-trigger`.

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
${JENKINS_URL}/job/${github.event.repository.name}/build?delay=0sec
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
