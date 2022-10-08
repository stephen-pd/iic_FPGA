.main clear

set CURENT_PART "inputBuffer"
set TOP_MODULE "tb_inputbuffer_top"

vlog -work work ../*.v

vsim -t 1ps -voptargs=+acc work.$TOP_MODULE -wav ./wave/inputbuffer_top.wlf
add wave -divider U_tb_inputbuffer_top
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/*


add wave -divider U_inputbuffer_top
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/U_inputbuffer_top/*

add wave -divider U_gen_waddr
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/U_inputbuffer_top/U_gen_waddr/*

add wave -divider U_gen_raddr
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/U_inputbuffer_top/U_gen_raddr/*

add wave -divider U_inputbuffer_sram_ctrl
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/U_inputbuffer_top/U_inputbuffer_sram_ctrl/*

add wave -divider U_sync_register
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/U_inputbuffer_top/U_sync_register/*

add wave -divider U_register_array_fifo
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/U_inputbuffer_top/U_register_array_fifo/*

add wave -divider U_gen_ready
add wave -format Logic -radix hexadecimal /tb_inputbuffer_top/U_inputbuffer_top/U_gen_ready/*

run 30ms -all


