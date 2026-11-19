#!/usr/bin/env bash
# Checks a unit's path against its YAML and writes the job's settings to
# $GITHUB_OUTPUT. Run from the repo root.
#   environments/<tier>/<env_id>/<region>/<cluster>/<component>[.<instance>].yaml
# In: FILE, ACTION, GITHUB_EVENT_NAME, GITHUB_REF, GITHUB_OUTPUT. Tests: read-unit.test.sh
set -euo pipefail
err() { echo "::error::$*"; exit 1; }
ident='^[a-z0-9]+(-[a-z0-9]+)*$'
shape="environments/<tier>/<env_id>/<region>/<cluster>/<component>[.<instance>].yaml"

# Paths reach shell commands and the job summary: a closed character set first.
[[ "$FILE" =~ ^[a-z0-9._/-]+$ ]] || err "unit path has unsupported characters (allowed: a-z 0-9 . _ / -)"
[ -f "$FILE" ] || err "$FILE does not exist"
IFS=/ read -r root tier env_id scope cluster file extra <<<"$FILE"
[[ "$root" = environments && -n "$file" && -z "$extra" && "$file" == *.yaml ]] || err "$FILE is not $shape"
unit="${file%.yaml}"; rs="${unit%%.*}"
if [ "$unit" != "$rs" ]; then
  [[ "${unit#*.}" =~ $ident ]] || err "instance '${unit#*.}' must match $ident"
fi
[ "$rs" != cluster ] && [ "$rs" != _boilerplate ] && [ -d "modules/$rs" ] || err "no component modules/$rs"

y() { yq -r "$1" "$FILE"; }
cloud=$(y '.cloud // "aws"')
[[ "$cloud" == aws || "$cloud" == azure ]] || err "cloud must be aws or azure, not $cloud"
[ "$(y .cluster)" = "$cluster" ] || err "cluster in the YAML ($(y .cluster)) does not match the path ($cluster)"
[ "$(y .tier)" = "$tier" ] || err "tier in the YAML ($(y .tier)) does not match the path ($tier)"
yaml_env_id=$(y '[.group, .environment, .requester] | map(select(. != null)) | join("-")')
[ "$yaml_env_id" = "$env_id" ] || err "env_id from the YAML ($yaml_env_id) does not match the path ($env_id)"
[ "$(y '.region // "global"')" = "$scope" ] || err "region in the YAML ($(y '.region // "global"')) does not match the path ($scope)"

# Pull requests plan as Terraform-Plan-Role (it trusts repo:<repo>:pull_request);
# everything dispatched runs from main as Terraform-Role (it trusts
# refs/heads/main). Both are the account baseline's (phoenix-aws-org;
# phoenix-aws ADR-0013).
if [ "$GITHUB_EVENT_NAME" != pull_request ] && [ "$GITHUB_REF" != refs/heads/main ]; then
  err "$ACTION only runs from main (or as a pull-request plan)"
fi
account_id=$(y .account_id)
[[ "$account_id" =~ ^[0-9]{12}$ ]] || err "account_id must be 12 digits"
if [ "$GITHUB_EVENT_NAME" = pull_request ]; then role=Terraform-Plan-Role; else role=Terraform-Role; fi

{
  echo "action=$ACTION"
  echo "cloud=$cloud"
  echo "resource_set=$rs"
  echo "module_ref=$(y '.module_ref // "main"')"
  echo "role_arn=arn:aws:iam::$account_id:role/$role"
  echo "aws_region=$(y '.region // "us-east-1"')"
  echo "state_bucket=$(y .state.bucket)"
  echo "state_region=$(y .state.region)"
  echo "state_kms_key_id=$(y '.state.kms_key_id // ""')"
  echo "state_key=$env_id/$scope/k8s/$cluster/$unit/terraform.tfstate"
} >> "$GITHUB_OUTPUT"
