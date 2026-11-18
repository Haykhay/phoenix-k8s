#!/usr/bin/env bash
# Tests read-unit.sh in a throwaway repo layout. Run: .github/scripts/read-unit.test.sh
set -uo pipefail
script="$(cd "$(dirname "$0")" && pwd)/read-unit.sh"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
cd "$work" && mkdir -p modules/vllm modules/cluster environments/sandbox/research-sandbox/eu-west-1/1
unit=environments/sandbox/research-sandbox/eu-west-1/1/vllm.yaml
cat > "$unit" <<'YAML'
organisation: acme
group: research
environment: sandbox
tier: sandbox
region: eu-west-1
cluster: "1"
account_id: "111111111111"
state:
  bucket: acme-tfstate-111111111111
  region: eu-west-1
YAML

fails=0
# run <file> <event> <ref> [action]: prints the script's outputs, returns its status
run() {
  out="$work/out"; : > "$out"
  FILE=$1 GITHUB_EVENT_NAME=$2 GITHUB_REF=$3 ACTION=${4:-plan} GITHUB_OUTPUT=$out "$script" >/dev/null 2>&1
  local rc=$?; cat "$out"; return $rc
}
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }

got=$(run "$unit" pull_request refs/pull/1/merge) || bad "valid unit is accepted"
grep -qx 'state_key=research-sandbox/eu-west-1/k8s/1/vllm/terraform.tfstate' <<<"$got" && ok "state key" || bad "state key: $got"
grep -qx 'resource_set=vllm' <<<"$got" && ok "resource set" || bad "resource set"
grep -qx 'role_arn=arn:aws:iam::111111111111:role/Terraform-Plan-Role' <<<"$got" && ok "pull requests plan as Terraform-Plan-Role" || bad "plan role"

got=$(run "$unit" workflow_dispatch refs/heads/main apply)
grep -qx 'role_arn=arn:aws:iam::111111111111:role/Terraform-Role' <<<"$got" && ok "main runs as Terraform-Role" || bad "main role"

run "$unit" workflow_dispatch refs/heads/feature apply >/dev/null && bad "dispatch from a branch is refused" || ok "dispatch from a branch is refused"

cp "$unit" environments/sandbox/research-sandbox/eu-west-1/1/nope.yaml
run environments/sandbox/research-sandbox/eu-west-1/1/nope.yaml pull_request x >/dev/null && bad "unknown component is refused" || ok "unknown component is refused"

mkdir -p environments/sandbox/research-sandbox/eu-west-1/2 && cp "$unit" environments/sandbox/research-sandbox/eu-west-1/2/vllm.yaml
run environments/sandbox/research-sandbox/eu-west-1/2/vllm.yaml pull_request x >/dev/null && bad "cluster mismatch is refused" || ok "cluster mismatch is refused"

echo "failing: $fails"; [ "$fails" = 0 ]
