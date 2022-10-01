quit -sim

set CURENT_PART "inputBuffer"
set TOP_MODULE "tb_apb_input_buffer"

#vlog ../RTL/$CURENT_PART/*.v
vlog ../rtl/input_buffer_port/*.v
vlog ../rtl/input_buffer/*.v
vlog ../rtl/utils/*.v
vlog ../tb/$TOP_MODULE.v

#vsim -voptargs=+acc work.tb_$TOP_MODULE
vsim -t 1ps -voptargs=+acc work.$TOP_MODULE

#add wave -r sim:/tb_apb_input_buffer/*
#add wave -r sim:/tb_apb_input_buffer/DUT/U_input_buffer_top_0/*

#run -all

