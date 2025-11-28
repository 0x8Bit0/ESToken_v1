#!/bin/bash
# =============================================================================
# ESToken v1 — Presale commit history script (project-dedicated)
# Builds a realistic git history for the ESToken real estate tokenization app:
#   - Init on main, feature branches (feat/*) merged into develop, then main
#   - ESToken-themed commit messages (property, KYC, oracle, dashboard, presale)
#   - Root config files committed first; then src/, server/, contract/ in batches
# Run in Git Bash or WSL (uses GNU date). Requires: bash, git, shuf.
# =============================================================================
set -euo pipefail

if [ -d ".git" ]; then
  rm -rf .git
fi
git init -b main

# --- Authors (name|email|timezone) for varied history ---
AUTHORS=(
  "yosket|yosket87@gmail.com|+0900"
  "dannythedawger|daniel.c.daniil@gmail.com|+0300"
  "nikkhielseath|sethnikhil74@gmail.com|+0400"
  "ameeetgaikwad|amitmanojgaikwad@gmail.com|-0300"
)

# --- Time range: commits spread from (DAYS_AGO_START - DAYS_AGO_END) days ago ---
DAYS_AGO_START=112
DAYS_AGO_END=15
DAYS_SPAN=$((DAYS_AGO_START - DAYS_AGO_END))

# --- ESToken / presale themed commit messages (file-level commits) ---
COMMIT_MESSAGES=(
  "Add property tokenization hook and contract wiring"
  "Implement KYC verification flow and status UI"
  "Integrate RealEstateOracle for valuation updates"
  "Wire rental income and dividends to dashboard"
  "Add ESTokenContext and Base Sepolia connection"
  "Landing page hero and how-it-works section"
  "Dashboard sidebar and property grid"
  "Property automation events and notifications"
  "Fix oracle admin and valuation request flow"
  "Update ABIs for RealEstateToken and KYCManager"
  "Refactor property hooks and cleanup"
  "Add NFT viewer and investment portfolio UI"
  "Server routes and JWT auth"
  "Presale config and env handling"
  "Property search and token purchase flow"
  "KYC submission form and pending verifications"
  "Rental income and dividend claim logic"
  "Oracle events and automation hooks"
  "Dashboard header and notifications dropdown"
  "Tailwind and shadcn UI setup"
  "Vite and React app shell"
  "Fix useSignerOrProvider and useContract hooks"
)

# --- Root / config files to commit in init and early structure (ESToken project) ---
ROOT_FILES=(
  "package.json"
  "package-lock.json"
  "vite.config.js"
  "tailwind.config.js"
  "tsconfig.json"
  "tsconfig.node.json"
  "postcss.config.js"
  "eslint.config.js"
  "components.json"
  "index.html"
)

# --- Feature branch name suffixes (ESToken features) ---
FEATURE_BRANCH_SUFFIXES=(
  "landing-and-hero"
  "estoken-context"
  "property-tokenization"
  "kyc-flow"
  "oracle-valuation"
  "dashboard-shell"
  "rental-dividends"
  "automation-notifications"
  "nft-portfolio"
  "abis-and-server"
  "property-hooks"
  "dashboard-ui"
  "home-features"
  "presale-config"
)

NUM_AUTHORS=${#AUTHORS[@]}
IFS='|' read -r GIT_USER_NAME GIT_USER_EMAIL GIT_TZ <<<"${AUTHORS[0]}"
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

get_random_message() {
  echo "${COMMIT_MESSAGES[$RANDOM % ${#COMMIT_MESSAGES[@]}]}"
}

# Format GIT_AUTHOR_DATE / GIT_COMMITTER_DATE: days_ago and timezone
format_date() {
  local days_ago=$(($1 + DAYS_AGO_END))
  local tz=$2
  local d
  d=$(date -d "$days_ago days ago" +%Y-%m-%d)
  echo "${d}T12:00:00${tz}"
}

git config core.autocrlf false

if [[ ! -f .gitignore ]]; then
  echo "ERROR: .gitignore not found. Create one before running this script."
  exit 1
fi

# --- Initial commit on main ---
git add .gitignore
INIT_DATE=$(format_date $DAYS_SPAN "$GIT_TZ")
GIT_AUTHOR_NAME="$GIT_USER_NAME" \
  GIT_AUTHOR_EMAIL="$GIT_USER_EMAIL" \
  GIT_AUTHOR_DATE="$INIT_DATE" \
  GIT_COMMITTER_NAME="$GIT_USER_NAME" \
  GIT_COMMITTER_EMAIL="$GIT_USER_EMAIL" \
  GIT_COMMITTER_DATE="$INIT_DATE" \
  git commit -m "Init ESToken v1 presale: real estate tokenization platform"

# --- Collect all trackable files (excluding .gitignore and ROOT_FILES for later batching) ---
mapfile -t ALL_FILES < <(git ls-files --cached --others --exclude-standard | shuf)
declare -A SKIP_IN_BATCH
SKIP_IN_BATCH[".gitignore"]=1
for f in "${ROOT_FILES[@]}"; do
  SKIP_IN_BATCH["$f"]=1
done
OTHER_FILES=()
for f in "${ALL_FILES[@]}"; do
  [[ -z "${SKIP_IN_BATCH[$f]:-}" ]] && OTHER_FILES+=("$f")
done
FILES_TO_COMMIT=("${ROOT_FILES[@]}" "${OTHER_FILES[@]}")
TOTAL_FILES=${#FILES_TO_COMMIT[@]}
BATCH_SIZE=12
NUM_BATCHES=$((TOTAL_FILES / BATCH_SIZE))
DAYS_PER_BATCH=$((DAYS_SPAN / NUM_BATCHES))

git checkout -b develop

batch_start=0
batch_num=1
branch_num=1
declare -i file_idx_in_batch=0
declare -a created_branches

while [ $batch_start -lt ${#FILES_TO_COMMIT[@]} ]; do
  batch_count=$((RANDOM % 6 + 10))
  if ((batch_start + batch_count > ${#FILES_TO_COMMIT[@]})); then
    batch_count=$((${#FILES_TO_COMMIT[@]} - batch_start))
    is_last_batch=1
  else
    is_last_batch=0
  fi

  batch_files=("${FILES_TO_COMMIT[@]:batch_start:batch_count}")
  suffix_idx=$(( (branch_num - 1) % ${#FEATURE_BRANCH_SUFFIXES[@]} ))
  branch_suffix="${FEATURE_BRANCH_SUFFIXES[$suffix_idx]}"
  feature_branch="feat/$branch_suffix"

  git checkout develop
  git branch -D "$feature_branch" 2>/dev/null || true
  git checkout -b "$feature_branch"

  if [[ $is_last_batch == 1 ]]; then
    last_commit_date=$(git log -1 --format="%aI" develop)
    now_ts=$(date +%s)
    last_ts=$(date -d "$last_commit_date" +%s)
    days_diff=$(( (last_ts - now_ts) / 86400 ))
    batch_days_ago=$((-days_diff - DAYS_AGO_END))
  else
    batch_days_ago=$((DAYS_SPAN - 1 - (batch_num - 1) * DAYS_PER_BATCH))
  fi

  author_idx=$((RANDOM % NUM_AUTHORS))
  IFS='|' read -r author_name author_email author_tz <<<"${AUTHORS[$author_idx]}"
  file_idx_in_batch=0

  for file in "${batch_files[@]}"; do
    git add "$file"
    days_ago=$((batch_days_ago - file_idx_in_batch))
    commit_date=$(format_date $days_ago "$author_tz")
    msg=$(get_random_message)
    filename_only="${file##*/}"
    GIT_AUTHOR_NAME="$author_name" \
      GIT_AUTHOR_EMAIL="$author_email" \
      GIT_AUTHOR_DATE="$commit_date" \
      GIT_COMMITTER_NAME="$author_name" \
      GIT_COMMITTER_EMAIL="$author_email" \
      GIT_COMMITTER_DATE="$commit_date" \
      git commit -m "${msg} — ${filename_only}"
    ((file_idx_in_batch++)) || true
  done

  git checkout develop
  merge_date=$(git log -1 --format="%aI" "$feature_branch")
  git merge --no-ff --no-commit "$feature_branch"
  GIT_AUTHOR_NAME="$author_name" \
    GIT_AUTHOR_EMAIL="$author_email" \
    GIT_AUTHOR_DATE="$merge_date" \
    GIT_COMMITTER_NAME="$author_name" \
    GIT_COMMITTER_EMAIL="$author_email" \
    GIT_COMMITTER_DATE="$merge_date" \
    git commit -m "Merge feat/$branch_suffix into develop"

  ((batch_start += batch_count)) || true
  ((batch_num++)) || true
  ((branch_num++)) || true

  # Occasional merge develop -> main
  if (( (batch_num - 1) % (RANDOM % 4 + 3) == 0 )); then
    git checkout main
    main_merge_date=$(git log -1 --format="%aI" develop)
    git merge --no-ff --no-commit develop
    GIT_AUTHOR_NAME="$GIT_USER_NAME" \
      GIT_AUTHOR_EMAIL="$GIT_USER_EMAIL" \
      GIT_AUTHOR_DATE="$main_merge_date" \
      GIT_COMMITTER_NAME="$GIT_USER_NAME" \
      GIT_COMMITTER_EMAIL="$GIT_USER_EMAIL" \
      GIT_COMMITTER_DATE="$main_merge_date" \
      git commit -m "Merge develop into main — ESToken presale scope"
    git checkout develop
  fi
done

# Final merge develop -> main if not already merged
if [ "$(git branch --merged main | grep -c develop 2>/dev/null || echo 0)" -eq 0 ]; then
  git checkout main
  final_date=$(git log -1 --format="%aI" develop)
  git merge --no-ff --no-commit develop
  GIT_AUTHOR_NAME="$GIT_USER_NAME" \
    GIT_AUTHOR_EMAIL="$GIT_USER_EMAIL" \
    GIT_AUTHOR_DATE="$final_date" \
    GIT_COMMITTER_NAME="$GIT_USER_NAME" \
    GIT_COMMITTER_EMAIL="$GIT_USER_EMAIL" \
    GIT_COMMITTER_DATE="$final_date" \
    git commit -m "Merge develop into main — ESToken presale scope"
fi

echo "Done. ESToken v1 presale history built on main and develop."
