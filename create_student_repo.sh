#!/usr/bin/env bash
#
# create_student_repo.sh
#
# Run this inside a clone of the starter repository:
#   https://github.com/Skylands-Research-Institute/xv6pp-riscv-labs.git
#
# Requirements:
#   - GitHub CLI (gh): https://cli.github.com
#   - git
#
# What it does:
#   1) Creates a private repo under the student's GitHub account.
#   2) Pushes the starter branches and tags already present in this VM clone to that new private repo.
#   3) Adds the instructor as a collaborator with push (write) permission.
#   4) Clones the new private repo as a sibling directory.

set -euo pipefail

# ========== EDIT THIS BEFORE YOU DISTRIBUTE ==================
INSTRUCTOR_GH="jsissler"
STARTER_REPO_URL="https://github.com/Skylands-Research-Institute/xv6pp-riscv-labs.git"
DEFAULT_NEW_REPO_NAME="xv6pp-riscv-labs-private"
DEFAULT_BRANCH="main"
DEFAULT_LAB_BRANCH="util"
# =============================================================

red()    { printf "\033[31m%s\033[0m\n" "$*" >&2; }
green()  { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    red "Error: '$1' is required but not installed."
    exit 1
  fi
}

normalize_git_url() {
  local url="$1"
  url="${url%.git}"
  if [[ "$url" =~ ^git@github\.com:(.*)$ ]]; then
    echo "https://github.com/${BASH_REMATCH[1]}"
  else
    echo "$url"
  fi
}

current_gh_login() {
  gh api user -q .login 2>/dev/null || true
}

# --- Pre-flight checks -------------------------------------------------------
need_cmd git
need_cmd gh

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  red "This script must be run inside a git repository (the starter repo you cloned)."
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if ! git remote get-url origin >/dev/null 2>&1; then
  red "This repository does not have an 'origin' remote."
  exit 1
fi

ORIGIN_URL_RAW="$(git remote get-url origin)"
ORIGIN_URL="$(normalize_git_url "$ORIGIN_URL_RAW")"
EXPECTED_URL="$(normalize_git_url "$STARTER_REPO_URL")"

if [[ "$ORIGIN_URL" != "$EXPECTED_URL" ]]; then
  red "This script must be run from a clone of:"
  red "  $EXPECTED_URL"
  red "Current origin is:"
  red "  $ORIGIN_URL"
  exit 1
fi

# --- Gather info -------------------------------------------------------------
STUDENT_LOGIN_DEFAULT="$(current_gh_login)"
STUDENT_LOGIN_DEFAULT="${STUDENT_LOGIN_DEFAULT:-student}"

PARENT_DIR="$(dirname "$REPO_ROOT")"
TARGET_DIR="${PARENT_DIR}/${DEFAULT_NEW_REPO_NAME}"

echo
yellow "=== Configure your private repository ==="
read -rp "Your GitHub username [${STUDENT_LOGIN_DEFAULT}]: " STUDENT_LOGIN
STUDENT_LOGIN="${STUDENT_LOGIN:-$STUDENT_LOGIN_DEFAULT}"
if [[ -z "$STUDENT_LOGIN" ]]; then
  red "GitHub username cannot be empty."
  exit 1
fi

read -rp "Name for your private repo [${DEFAULT_NEW_REPO_NAME}]: " NEW_REPO_NAME
NEW_REPO_NAME="${NEW_REPO_NAME:-$DEFAULT_NEW_REPO_NAME}"
TARGET_FULL="${STUDENT_LOGIN}/${NEW_REPO_NAME}"

TARGET_DIR="${PARENT_DIR}/${NEW_REPO_NAME}"

read -rp "Instructor's GitHub username [${INSTRUCTOR_GH}]: " INSTRUCTOR_INPUT
INSTRUCTOR_GH="${INSTRUCTOR_INPUT:-$INSTRUCTOR_GH}"

read -rp "Lab branch you plan to work on [${DEFAULT_LAB_BRANCH}]: " LAB_BRANCH
LAB_BRANCH="${LAB_BRANCH:-$DEFAULT_LAB_BRANCH}"

# --- Ensure gh is authenticated as the student ------------------------------
CURRENT_GH_LOGIN="$(current_gh_login)"
if [[ -z "$CURRENT_GH_LOGIN" ]]; then
  yellow "GitHub CLI is not authenticated."
  yellow "Please log in as ${STUDENT_LOGIN}."
  gh auth login
  CURRENT_GH_LOGIN="$(current_gh_login)"
fi

if [[ "$CURRENT_GH_LOGIN" != "$STUDENT_LOGIN" ]]; then
  yellow "GitHub CLI is currently authenticated as '${CURRENT_GH_LOGIN}', but this repo should be created under '${STUDENT_LOGIN}'."
  yellow "Logging out and re-authenticating now."
  gh auth logout -h github.com || true
  gh auth login
  CURRENT_GH_LOGIN="$(current_gh_login)"
fi

if [[ "$CURRENT_GH_LOGIN" != "$STUDENT_LOGIN" ]]; then
  red "GitHub CLI is authenticated as '${CURRENT_GH_LOGIN}', not '${STUDENT_LOGIN}'."
  red "Please rerun the script after logging in as the student."
  exit 1
fi

gh auth setup-git >/dev/null

echo
yellow "Starter source: ${EXPECTED_URL}"
yellow "You are about to create: https://github.com/${TARGET_FULL} (private)"
read -rp "Continue? [y/N]: " CONFIRM
CONFIRM="${CONFIRM:-N}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  red "Aborted."
  exit 1
fi

# --- Create the repo ---------------------------------------------------------
green "Creating private repository ${TARGET_FULL} ..."
REPO_ALREADY_EXISTS=0
if gh repo view "$TARGET_FULL" >/dev/null 2>&1; then
  REPO_ALREADY_EXISTS=1
  yellow "Repo ${TARGET_FULL} already exists."
  yellow "Reusing it will push starter branches and tags with --prune."
  yellow "Any branches in ${TARGET_FULL} that are not present in starter origin may be deleted."
  read -rp "Type the repo name '${NEW_REPO_NAME}' to reuse it: " REUSE_CONFIRM
  if [[ "$REUSE_CONFIRM" != "$NEW_REPO_NAME" ]]; then
    red "Aborted."
    exit 1
  fi
else
  gh repo create "$TARGET_FULL" --private --description "Private labs for ${STUDENT_LOGIN}" >/dev/null
  green "Created."
fi

# --- Push EVERYTHING to the new repo ----------------------------------------
yellow "Preparing starter branches and tags from this VM clone..."

CLONE_URL="$(gh api "repos/${TARGET_FULL}" -q .clone_url)"
STUDENT_REMOTE="student"
if git remote get-url "$STUDENT_REMOTE" >/dev/null 2>&1; then
  git remote remove "$STUDENT_REMOTE"
fi
git remote add "$STUDENT_REMOTE" "$CLONE_URL"

if [[ "$REPO_ALREADY_EXISTS" -eq 1 ]]; then
  green "Synchronizing ALL starter branches and tags to the existing private repo..."
else
  green "Pushing ALL branches and tags to the private repo..."
fi

mapfile -t STARTER_REFS < <(git for-each-ref --format='%(refname)' refs/remotes/origin refs/tags | grep -v '^refs/remotes/origin/HEAD$')
if [[ "${#STARTER_REFS[@]}" -eq 0 ]]; then
  red "No starter branches or tags were found in this VM clone."
  red "Please ask your instructor for a refreshed VM image."
  git remote remove "$STUDENT_REMOTE"
  exit 1
fi

PUSH_REFS=()
for ref in "${STARTER_REFS[@]}"; do
  case "$ref" in
    refs/remotes/origin/*)
      branch="${ref#refs/remotes/origin/}"
      PUSH_REFS+=("${ref}:refs/heads/${branch}")
      ;;
    refs/tags/*)
      PUSH_REFS+=("${ref}:${ref}")
      ;;
  esac
done

git push --prune "$STUDENT_REMOTE" "${PUSH_REFS[@]}"

# --- Set default branch ------------------------------------------------------
green "Setting default branch to ${DEFAULT_BRANCH}..."
gh api -X PATCH "repos/${TARGET_FULL}" -f default_branch="${DEFAULT_BRANCH}" >/dev/null

# --- Remove temporary remote -------------------------------------------------
git remote remove "$STUDENT_REMOTE"

# --- Add instructor as collaborator -----------------------------------------
green "Adding instructor (${INSTRUCTOR_GH}) as collaborator with 'push' permission..."
gh api \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/${TARGET_FULL}/collaborators/${INSTRUCTOR_GH}" \
  -f permission=push >/dev/null

# --- Clone the new private repo next to the current directory ----------------
if [[ -e "$TARGET_DIR" ]]; then
  yellow "Directory '${TARGET_DIR}' already exists. Skipping clone."
else
  green "Cloning the new private repo to: ${TARGET_DIR}"
  gh repo clone "${TARGET_FULL}" "${TARGET_DIR}" >/dev/null
fi

if [[ -d "${TARGET_DIR}/.git" ]]; then
  green "Checking out lab branch ${LAB_BRANCH} in ${TARGET_DIR}..."
  git -C "$TARGET_DIR" checkout "$LAB_BRANCH" >/dev/null
fi

green "Done!"

cat <<EOF

=============================================================
Success!

- Starter source verified as:
    ${EXPECTED_URL}

- Your private repo:
    https://github.com/${TARGET_FULL}

- Local clone created at:
    ${TARGET_DIR}

- Instructor (${INSTRUCTOR_GH}) has been added as a collaborator.

- You can now start working on the correct lab branch, e.g.:

    cd "${TARGET_DIR}"
    git checkout ${LAB_BRANCH}

Don't forget to commit & push your work regularly:

    git add .
    git commit -m "${LAB_BRANCH} lab progress"
    git push

Preferably, you should use the GitHub Desktop application to manage your repository.

=============================================================
EOF
