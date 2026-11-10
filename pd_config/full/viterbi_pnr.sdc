create_clock -name clk -period 5.000 -waveform {0.000 2.500} [get_ports clk]
set clocks [get_clocks clk]
set data_inputs [get_ports {in_valid codeword_in* out_ready}]
set data_outputs [all_outputs]

set_input_delay -clock $clocks -min 0.10 $data_inputs
set_input_delay -clock $clocks -max 0.50 $data_inputs
set_output_delay -clock $clocks -min 0.10 $data_outputs
set_output_delay -clock $clocks -max 0.50 $data_outputs
set_input_transition 0.10 $data_inputs
set_input_transition 0.10 [get_ports rst_n]
set_load 0.010 $data_outputs

# Only r_sync may contain asynchronous-reset FFs in this design.
set reset_async_pins [all_registers -async_pins]
if {[llength $reset_async_pins] > 0} {
    set_false_path -from [get_ports rst_n] -to $reset_async_pins
} else {
    set_input_delay -clock $clocks -clock_fall -rise -min 0.10 [get_ports rst_n]
    set_input_delay -clock $clocks -clock_fall -rise -max 0.50 [get_ports rst_n]
}

set_clock_uncertainty -setup 0.15 $clocks
set_clock_uncertainty -hold 0.05 $clocks
set_clock_transition 0.10 $clocks

set_max_fanout 10 [current_design]
set_max_transition 0.75 [current_design]
set_max_capacitance 0.20 [current_design]
set_timing_derate -early 0.95
set_timing_derate -late 1.05

if {[info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS)} {
    unset_propagated_clock [all_clocks]
} else {
    set_propagated_clock [all_clocks]
}
