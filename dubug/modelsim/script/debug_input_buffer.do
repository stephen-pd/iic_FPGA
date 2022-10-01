.main clear

set CURENT_PART "inputBuffer"
set TOP_MODULE "tb_apb_input_buffer"



vlog -work work ./rtl/input_buffer_port/*.v
vlog -work work ./rtl/input_buffer/*.v
vlog -work work ./rtl/utils/*.v
vlog -work work ./tb/$TOP_MODULE.v

vsim -t 1ps -voptargs=+acc work.$TOP_MODULE

#add wave -r sim:/tb_apb_input_buffer/*
add wave -r sim:/tb_apb_input_buffer/DUT/U_input_buffer_top_0/*

run -all


