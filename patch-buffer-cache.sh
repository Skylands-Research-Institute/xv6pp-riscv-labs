#!/usr/bin/env bash
# Run from your private xv6pp-riscv-labs clone.
set -euo pipefail

if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  printf '%s\n' 'Run this script from your private xv6pp-riscv-labs clone.' >&2
  exit 1
fi
cd "$repo_root"
remote=$(git remote get-url --push origin)

temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT
git clone --quiet --no-checkout -- "$remote" "$temp_dir/repo"

# Honor the commit identity configured in the student's original clone.
for key in user.name user.email; do
  if value=$(git config --get "$key"); then
    git -C "$temp_dir/repo" config "$key" "$value"
  fi
done
cd "$temp_dir/repo"

file=kernel/buffer_cache.cpp
patch=$(cat <<'PATCH'
diff --git a/kernel/buffer_cache.cpp b/kernel/buffer_cache.cpp
--- a/kernel/buffer_cache.cpp
+++ b/kernel/buffer_cache.cpp
@@ -55,7 +55,7 @@ void buffer_cache::relse(buf *b) {
   b->refcnt--;
   if (b->refcnt == 0) {
     // Move to front of LRU list
     cache.remove(b);
-    cache.push_back(b);
+    cache.push_front(b);
   }
 }
PATCH
)

refs=$(git for-each-ref --format='%(refname) %(symref)' refs/remotes/origin/)
updates=()
while read -r ref symref; do
  if [[ -z "$ref" || -n "$symref" ]]; then
    continue
  fi
  branch=${ref#refs/remotes/origin/}
  git switch --quiet --detach "$ref"
  if git apply --reverse --check <<< "$patch" 2>/dev/null; then
    printf '%s already has the fix.\n' "$branch"
    continue
  fi
  if ! git apply --index <<< "$patch"; then
    printf 'Could not patch %s on %s. No branches were pushed.\n' "$file" "$branch" >&2
    exit 1
  fi
  git diff --cached --check
  git commit --quiet -m "Fix buffer cache eviction order"
  updates+=("$(git rev-parse HEAD):refs/heads/$branch")
  printf 'Prepared the fix for %s.\n' "$branch"
done <<< "$refs"

if (( ${#updates[@]} == 0 )); then
  printf '%s\n' 'No branch updates to push.'
  exit 0
fi

git push --atomic origin "${updates[@]}"
printf '%s\n' 'Updated your private repository on the server. Your local branches can pull the fix.'
