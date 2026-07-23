#!/usr/bin/env bash
# Public-source secret gate.
#
# Scans the content this repository actually publishes -- the git-tracked
# worktree -- with Gitleaks. Candidate values are never printed (--redact=100).
#
# Scope: tracked files, not full history. This gate exists to stop something
# new from being published. Existing history was audited separately; scanning
# it here would hold the gate permanently red on old commits that have already
# been reviewed and cannot be rewritten without breaking forks and clones.
#
# Gitleaks only, deliberately. TruffleHog without verification flags ordinary
# identifiers (it trips on Swift test-method names), and running it *with*
# verification would send candidate secrets off-box.
#
# Reviewed non-secrets belong in .gitleaks.toml, not in an exception here.
set -euo pipefail

# Non-interactive shells (CI, ssh) often omit Homebrew from PATH.
for tool_directory in /opt/homebrew/bin /usr/local/bin; do
  [[ -d "${tool_directory}" ]] && PATH="${tool_directory}:${PATH}"
done
export PATH

repo_root="$(git -C "$(dirname "${BASH_SOURCE[0]}")/.." rev-parse --show-toplevel)"

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
  [[ -f "${repo_root}/${tracked_path}" ]] || continue
  mkdir -p "${snapshot}/$(dirname "${tracked_path}")"
  cp -p "${repo_root}/${tracked_path}" "${snapshot}/${tracked_path}"
done < <(git -C "${repo_root}" ls-files -z)

if [[ -f "${repo_root}/.gitleaks.toml" ]]; then
  gitleaks dir \
    --no-banner \
    --redact=100 \
    --config "${repo_root}/.gitleaks.toml" \
    "${snapshot}"
else
  gitleaks dir \
    --no-banner \
    --redact=100 \
    "${snapshot}"
fi

printf 'PASS: Gitleaks found no secrets in the tracked worktree.\n'
