# syntax=docker/dockerfile:1
# bash-course:2.0 — the course's learner environment.
# Status: DESIGNED, NOT BUILT in the authoring environment (no Docker daemon was
# reachable). Verification task V-01 (see 00-BRIEF-AND-BLUEPRINT.md) builds it and
# runs the course's own checks inside it before the image is called "validated".
#
# Pinning: do not copy a digest from anywhere. After your first successful pull/build,
# RECORD the real digests with:
#   docker image inspect --format '{{index .RepoDigests 0}}' ubuntu:24.04
# and write them into env/MANIFEST.txt for your cohort.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Everything Modules M00–M08 need: bash 5.x (ships with the base), coreutils,
# grep/sed/awk, util-linux (flock), shellcheck, jq, curl, git. Versions are the
# distro's; record the ones you actually get (tools-check.sh prints them).
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash coreutils grep sed gawk util-linux \
      shellcheck jq curl git ca-certificates less nano \
      python3 make \
 && rm -rf /var/lib/apt/lists/*

# A non-root learner account: labs must never need root.
RUN useradd -m -s /bin/bash learner
USER learner
WORKDIR /course

# The course bundle is bind-mounted at /course (see env/README.md).
CMD ["bash"]
