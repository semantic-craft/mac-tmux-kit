#!/usr/bin/env bash
# Public-source secret gate.
#
#   check-secrets.sh [target-dir]
#
# Scans the git-tracked content of <target-dir> (default: this repository) with
# Gitleaks. Candidate values are never printed (--redact=100).
#
# Why the target is a parameter
# -----------------------------
# On a pull request the tree under review is UNTRUSTED: it can rewrite this
# script and the gitleaks config to pass itself. So CI checks out the trusted
# base branch (which is where this script runs from) and passes the pull
# request's tree as <target-dir> — data to be inspected, never code to run.
# The scanner and its config always come from the trusted checkout.
#
# Scope: tracked files, not full history. This gate stops something new from
# being published. Existing history is covered by pre-publish-audit.sh, which
# is run once before a repository is made public.
#
# Gitleaks only, deliberately. TruffleHog without verification flags ordinary
# identifiers (it trips on Swift test-method names), and running it *with*
# verification would send candidate secrets off-box.
#
# Reviewed non-secrets belong in .gitleaks.toml, not in an exception here.
set -euo pipefail

# Hooks and non-interactive shells inherit a minimal PATH.
for tool_directory in /opt/homebrew/bin /usr/local/bin; do
  [[ -d "${tool_directory}" ]] && PATH="${tool_directory}:${PATH}"
done
export PATH

# Trusted root: wherever THIS script lives. The config is read from here, never
# from the tree under review.
trusted_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
target="${1:-${trusted_root}}"
target="$(cd "${target}" && pwd)"

command -v gitleaks >/dev/null || {
  printf 'secret gate: gitleaks is required but was not found\n' >&2
  exit 2
}

# Snapshot only tracked files, so gitignored local material (real .env files,
# build output, caches) is never scanned and never reported.
snapshot="$(mktemp -d "${TMPDIR:-/tmp}/secret-gate.XXXXXX")"
cleanup() { rm -rf -- "${snapshot}"; }
trap cleanup EXIT HUP INT TERM

while IFS= read -r -d '' tracked_path; do
  [[ -f "${target}/${tracked_path}" ]] || continue
  mkdir -p "${snapshot}/$(dirname "${tracked_path}")"
  cp -p "${target}/${tracked_path}" "${snapshot}/${tracked_path}"
done < <(git -C "${target}" ls-files -z)

# Gitleaks auto-discovers a .gitleaks.toml inside the directory it scans. If the
# tree under review carried one, that untrusted config would silently govern the
# scan — a pull request could ship `[allowlist] paths=[".*"]` and pass itself.
# Strip every config out of the snapshot; the trusted one is passed explicitly.
find "${snapshot}" -name '.gitleaks.toml' -type f -delete 2>/dev/null || true

if [[ -f "${trusted_root}/.gitleaks.toml" ]]; then
  gitleaks dir \
    --no-banner \
    --redact=100 \
    --config "${trusted_root}/.gitleaks.toml" \
    "${snapshot}"
else
  gitleaks dir \
    --no-banner \
    --redact=100 \
    "${snapshot}"
fi

if [[ "${target}" == "${trusted_root}" ]]; then
  printf 'PASS: Gitleaks found no secrets in the tracked worktree.\n'
else
  printf 'PASS: Gitleaks found no secrets in the tree under review (%s).\n' "${target}"
fi
