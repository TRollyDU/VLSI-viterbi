#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
scope=${1:-both}
if (( $# > 1 )) || [[ ! "$scope" =~ ^(core|full|both)$ ]]; then echo "Usage: bash pd_config/run_librelane.sh [core|full|both]" >&2; exit 2; fi
: "${PDK_ROOT:?Set PDK_ROOT to the directory containing sky130A}"
command -v librelane >/dev/null || { echo 'Activate the LibreLane tool environment first.' >&2; exit 2; }
scopes=("$scope"); [[ "$scope" != both ]] || scopes=(core full)
mkdir -p "$root/experiment/pd_runs"
run=$(mktemp -d "$root/experiment/pd_runs/baseline_XXXXXXXX")
mkdir "$run/rtl"; cp "$root"/rtl/*.v "$run/rtl/"
for item in "${scopes[@]}"; do
 mkdir -p "$run/pd/$item"
 cp "$root/pd_config/$item/"* "$run/pd/$item/"
done
sha256sum "$run"/rtl/*.v "$run"/pd/*/* > "$run/source_sha256.txt"
printf 'Run directory: %s\n' "$run"
for item in "${scopes[@]}"; do
 librelane --manual-pdk --pdk-root "$PDK_ROOT" --pdk sky130A --scl sky130_fd_sc_hd   --run-tag baseline_5ns --jobs "${JOBS:-6}" --condensed "$run/pd/$item/config.json"   > "$run/pd/$item/console.log" 2>&1
 python3 "$root/pd_config/report_metrics.py" "$run/pd/$item/runs/baseline_5ns/final/metrics.json"
done
