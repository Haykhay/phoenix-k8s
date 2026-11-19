#!/usr/bin/env bash
# Tests scripts/stage-module. Run from anywhere: scripts/tests/stage-module.test.sh
set -uo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
stage="$root/scripts/stage-module"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
fails=0
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }

"$stage" "$root/modules/opencost" aws "$work/aws" >/dev/null 2>&1 || bad "stages opencost for aws"
grep -q 'backend "s3"' "$work/aws/backend.tf" 2>/dev/null && ok "aws stage has the S3 backend" || bad "aws stage has the S3 backend"
grep -q 'provider "aws"' "$work/aws/provider.tf" 2>/dev/null && ok "aws stage has the aws provider" || bad "aws stage has the aws provider"
[ -f "$work/aws/main.tf" ] && [ -d "$work/aws/tests/aws" ] && ok "the module and its tests are copied" || bad "the module and its tests are copied"
grep -q 'source *= *"\.\./cluster"' "$work/aws/_context.tf" 2>/dev/null && bad "relative sources are rewritten" || ok "relative sources are rewritten"
src=$(sed -nE 's/^ *source *= *"([^"]*cluster)"/\1/p' "$work/aws/_context.tf" 2>/dev/null)
[ -n "$src" ] && [ -f "$work/aws/$src/main.tf" ] && ok "the rewritten cluster source resolves from the stage" || bad "the rewritten cluster source resolves ($src)"

"$stage" "$root/modules/opencost" azure "$work/azure" >/dev/null 2>&1 || bad "stages opencost for azure"
grep -q 'backend "azurerm"' "$work/azure/backend.tf" 2>/dev/null && ok "azure stage has the azurerm backend" || bad "azure stage has the azurerm backend"
grep -qs '^provider "aws"' "$work/azure"/*.tf && bad "azure stage has no aws provider" || ok "azure stage has no aws provider"

mkdir -p "$work/mod/cloud/aws" && cp -R "$root/modules/opencost/." "$work/mod/" 2>/dev/null
printf 'locals {\n  slice = {}\n}\n' > "$work/mod/cloud/aws/slice.tf"
"$stage" "$work/mod" aws "$work/sliced" >/dev/null 2>&1
[ -f "$work/sliced/slice.tf" ] && [ ! -d "$work/sliced/cloud" ] && ok "cloud/<cloud>/*.tf is flattened into the stage" || bad "cloud/<cloud>/*.tf is flattened into the stage"

"$stage" "$root/modules/opencost" gcp "$work/gcp" >/dev/null 2>&1 && bad "an unknown cloud is refused" || ok "an unknown cloud is refused"

echo "failing: $fails"; [ "$fails" = 0 ]
