.main clear

set CURENT_PART "inputBuffer"
set TOP_MODULE "tb_apb_input_buffer"

vlog ./rtl/input_buffer_port/*.v
vlog ./rtl/input_buffer/*.v
vlog ./rtl/utils/*.v
vlog ./tb/$TOP_MODULE.v

vsim -t 1ps -voptargs=+acc work.$TOP_MODULE

vcd file ./modelsim/waveform/$TOP_MODULE.vcd
vcd add /*

run -all

quit -sim

vcd2wlf ./modelsim/waveform/$TOP_MODULE.vcd ./modelsim/waveform/$TOP_MODULE.wlf

vsim -view ./modelsim/waveform/$TOP_MODULE.wlf

