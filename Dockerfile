FROM ubuntu:24.04

# Define the runner version as an argument with a default value
ARG RUNNER_VERSION=2.335.1

# Avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    build-essential \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for the runner to execute safely
RUN useradd -m runner
USER runner
WORKDIR /home/runner

# Download the specific runner package using the ARG
ARG RUNNER_SHA256=4ef2f25285f0ae4477f1fe1e346db76d2f3ebf03824e2ddd1973a2819bf6c8cf
RUN curl -fsSL -o actions-runner-linux-x64.tar.gz "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && echo "${RUNNER_SHA256}  actions-runner-linux-x64.tar.gz" | sha256sum -c - \
    && tar xzf ./actions-runner-linux-x64.tar.gz \
    && rm actions-runner-linux-x64.tar.gz

# Install runner dependencies
USER root
RUN ./bin/installdependencies.sh
USER runner

COPY --chown=runner:runner entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
