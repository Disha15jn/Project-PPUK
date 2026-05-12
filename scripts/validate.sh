#!/usr/bin/env bash
set -euo pipefail

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required but was not found on PATH" >&2
  exit 127
fi

cd "$(dirname "$0")/../terraform"
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
