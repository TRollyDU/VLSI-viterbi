#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
selection=${1:-all}
if (( $# > 1 )); then echo "Usage: bash tb/scripts/run_questa.sh [all|blocks|system|tb_name]" >&2; exit 2; fi
blocks=(tb_bmu tb_acs tb_pmu tb_piso tb_re tb_controller tb_iu tb_ou tb_r_sync)
system=(tb_psu tb_top tb_exhaustive tb_options tb_reset tb_core_protocol)
case "$selection" in
 all) benches=("${blocks[@]}" "${system[@]}");;
 blocks) benches=("${blocks[@]}");;
 system) benches=("${system[@]}");;
 *) benches=(); for bench in "${blocks[@]}" "${system[@]}"; do [[ "$selection" != "$bench" ]] || benches+=("$bench"); done
    if (( ${#benches[@]} == 0 )); then echo "Unknown bench: $selection" >&2; exit 2; fi;;
esac
for tool in python3 vlib vmap vlog vsim; do command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 2; }; done
mkdir -p "$root/experiment/tb_runs"
run=$(mktemp -d "$root/experiment/tb_runs/questa_XXXXXXXX")
cd "$run"
printf 'Run directory: %s\n' "$run"
vsim -version > version.txt 2>&1
python3 "$root/tb/scripts/generate_oracle.py" "$run" > oracle_generation.log
cp "$root/tb/data/input.txt" "$root/tb/data/output.txt" .
vmap -c > library.log 2>&1
vlib work >> library.log 2>&1
vmap -modelsimini modelsim.ini work "$run/work" >> library.log 2>&1
rtl=("$root"/rtl/*.v)
tests=(); for bench in "${benches[@]}"; do
 file="$root/tb/$bench.sv"; [[ -f "$file" ]] || file="$root/tb/$bench.v"; tests+=("$file")
done
sha256sum "${rtl[@]}" "${tests[@]}" "$root/tb/scripts/run_questa.sh" "$root/tb/scripts/generate_oracle.py" "$root/tb/data/input.txt" "$root/tb/data/output.txt" > source_sha256.txt
vlog -modelsimini modelsim.ini -sv -work work "${rtl[@]}" "${tests[@]}" > compile.log 2>&1
for bench in "${benches[@]}"; do
 vsim -c -modelsimini modelsim.ini -onfinish exit -wlf "$bench.wlf" -l "$bench.log" "work.$bench"    -do 'run -all; quit -f -code 0' > "$bench.console.log" 2>&1
 if grep -Eiq '(^|# +)(Fatal:|Error:|FAIL|\*\* +(Error|Fatal):)' "$bench.log"; then echo "FAIL: $bench (see $run/$bench.log)" >&2; exit 1; fi
 if [[ "$bench" == tb_top ]]; then
  grep -q 'COMPARE SUMMARY: total=1025 pass=1025 fail=0' "$bench.log"
 else
  grep -q 'PASS:' "$bench.log"
 fi
 printf 'PASS: %s\n' "$bench" | tee -a summary.txt
done
printf 'PASS: %s (%s benches)\n' "$selection" "${#benches[@]}" | tee -a summary.txt
