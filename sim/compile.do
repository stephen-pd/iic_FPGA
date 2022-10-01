.main clear
vlog -reportprogress 300 -work work ./define.v
vlog -reportprogress 300 -work work ./tb_top.v
vlog -reportprogress 300 -work work ./top.v
vlog -reportprogress 300 -work work ./gen_waddr.v
vlog -reportprogress 300 -work work ./gen_raddr.v

vlog -reportprogress 300 -work work ./gen_sram_interface.v
vlog -reportprogress 300 -work work ./reg_array_fifo_ctrl.v
vlog -reportprogress 300 -work work ./sram_sim.v
vlog -reportprogress 300 -work work ./sram.v
vlog -reportprogress 300 -work work ./sync_reg.v
vlog -reportprogress 300 -work work ./mux_8_1.v
vlog -reportprogress 300 -work work ./mux_ctrl_8_1.v
vlog -reportprogress 300 -work work ./mux_6_1.v
vlog -reportprogress 300 -work work ./mux_ctrl_6_1.v