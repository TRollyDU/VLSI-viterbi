#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
selection=${1:-all}
blocks=(tb_r_sync tb_controller tb_piso tb_bmu tb_butterfly tb_pmu tb_smu)
system=(tb_viterbi_exhaustive tb_viterbi_control)
case "$selection" in
    all) benches=("${blocks[@]}" "${system[@]}");;
    blocks) benches=("${blocks[@]}");;
    exhaustive) benches=(tb_viterbi_exhaustive);;
    control) benches=(tb_viterbi_control);;
    *) benches=(); for bench in "${blocks[@]}" "${system[@]}"; do
        [[ "$selection" != "$bench" ]] || benches+=("$bench")
       done
       (( ${#benches[@]} > 0 )) || { echo "Unknown test: $selection" >&2; exit 2; };;
esac
for tool in python3 vlib vmap vlog vsim vcover; do command -v "$tool" >/dev/null; done
mkdir -p "$root/experiment/tb_runs"
run=$(mktemp -d "$root/experiment/tb_runs/smu_questa_XXXXXXXX")
mkdir "$run/rtl" "$run/tb"
cp "$root"/rtl/*.v "$run/rtl/"
cp "$root"/tb/*.sv "$run/tb/"
cp "$root/tb/scripts/generate_oracle.py" "$run/"
cp "$root/tb/scripts/run_questa.sh" "$run/"
printf '%s\n' "$run" > "$root/experiment/tb_runs/latest_smu_run.txt"
cd "$run"
printf 'RUN %s\n' "$run"
vsim -version > version.txt 2>&1
python3 -B generate_oracle.py "$run" > oracle_generation.log
sha256sum rtl/*.v tb/*.sv generate_oracle.py run_questa.sh oracle.hex clean_codewords.hex > source_sha256.txt
vmap -c > library.log 2>&1
vlib work >> library.log 2>&1
vmap -modelsimini modelsim.ini work "$run/work" >> library.log 2>&1
vlog -modelsimini modelsim.ini +cover=bcesf -work work rtl/*.v > compile_rtl.log 2>&1
vlog -modelsimini modelsim.ini -sv -work work tb/*.sv > compile_tb.log 2>&1
for bench in "${benches[@]}"; do
    vsim -c -modelsimini modelsim.ini -coverage -voptargs=+acc -onfinish exit \
        -wlf "$bench.wlf" -l "$bench.log" "work.$bench" \
        -do "coverage save -onexit $bench.ucdb; run -all; quit -f -code 0" > "$bench.console.log" 2>&1
    if grep -Eiq '(^|# +)(Fatal:|Error:|FAIL|\*\* +(Error|Fatal):)' "$bench.log"; then
        echo "FAIL $bench: $run/$bench.log" >&2; exit 1
    fi
    grep -q 'PASS:' "$bench.log"
    printf 'PASS: %s\n' "$bench" | tee -a summary.txt
done
vcover merge coverage.ucdb ./*.ucdb > coverage_merge.log 2>&1
vcover report -details -code bcesf coverage.ucdb > coverage.txt 2>&1
vcover report -bydu -details -code bcesf coverage.ucdb > coverage_by_design_unit.txt 2>&1
vcover report -html -htmldir coverage_html -code bcesf coverage.ucdb > coverage_html.log 2>&1
printf 'PASS: %s (%s benches)\n' "$selection" "${#benches[@]}" | tee -a summary.txt
