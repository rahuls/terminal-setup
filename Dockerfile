FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Keep image small but include tools used by setup workflows.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  sudo \
  git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /workspace

# Default to an interactive shell so scripts/setup.sh can be run manually.
CMD ["bash"]
