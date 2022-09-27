quit -sim

set CURENT_PART "inputBuffer"
set TOP_MODULE "tb_apb_input_buffer_port"

#vlog ../RTL/$CURENT_PART/*.v
vlog ../rtl/input_buffer_port/*.v
vlog ../rtl/utils/*.v
vlog ../tb/$TOP_MODULE.v

#vsim -voptargs=+acc work.tb_$TOP_MODULE
vsim -voptargs=+acc work.$TOP_MODULE

vcd file ./waveform/$TOP_MODULE.vcd
vcd add /*

run -all

quit -sim

vcd2wlf ./waveform/$TOP_MODULE.vcd ./waveform/$TOP_MODULE.wlf

vsim -view ./waveform/$TOP_MODULE.wlf

add wave -position insertpoint  \
tb_apb_input_buffer_port:/tb_apb_input_buffer_port/DUT/dut/inbuf_hsync_o  \
tb_apb_input_buffer_port:/tb_apb_input_buffer_port/DUT/dut/inbuf_cmd_fire  \
tb_apb_input_buffer_port:/tb_apb_input_buffer_port/DUT/dut/inbuf_sop_o  \
tb_apb_input_buffer_port:/tb_apb_input_buffer_port/DUT/dut/program_id_fire \
tb_apb_input_buffer_port:/tb_apb_input_buffer_port/DUT/dut/program_id_payload_i \
tb_apb_input_buffer_port:/tb_apb_input_buffer_port/DUT/dut/program_id_triggerd_i