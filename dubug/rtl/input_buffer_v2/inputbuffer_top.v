`include "define.v"
module inputbuffer_top #(
    parameter dw=128,
    parameter aw=10
)(
    input   SYS_CLK,
    input   SYS_NRST,

    input   [3:0]mode,
    input   padding,
    input   [5:0]pic_size,

    input   [dw-1 :0]input_buffer_write_data,
    input   input_buffer_write_sop,
    input   input_buffer_write_hsync,
    input   [aw-1 :0]input_buffer_write_addr_start,
    input   input_buffer_write_valid,
    output  input_buffer_write_ready,
    
    input   sram2reg_valid,
    output  sram2reg_ready,

    input   opu1152_ready,
    output  opu1152_valid,
    output  [dw*9-1 :0]opu1152_data,

    input   [10:0]register_array_row_sel,
    output  [7:0]register_array_row_data  
);

wire sram2reg_handshake;
assign sram2reg_handshake = sram2reg_valid&sram2reg_ready;
//===========================================
// description: in mode[2], fake handshake
wire register2opu_valid;
wire register2opu_ready;
wire register2opu_handshake;
reg [3:0]r_cnt_handshake;

assign register2opu_handshake = register2opu_valid & register2opu_ready;
always @(posedge SYS_CLK or negedge SYS_NRST) begin
    if (!SYS_NRST)begin
        r_cnt_handshake <= 'b0;
    end
    else begin
        if (sram2reg_handshake || input_buffer_write_sop)begin
            r_cnt_handshake <= 'b0;
        end
        else if(register2opu_handshake)begin
            r_cnt_handshake <= r_cnt_handshake + 1'b1;
        end
    end
end

assign opu1152_valid = mode[2] ? ((r_cnt_handshake < 'd8) ? register2opu_valid : 1'b0) : (register2opu_valid);
assign register2opu_ready = mode[2] ? ((r_cnt_handshake < 'd8) ? opu1152_ready : 1'b1) : (opu1152_ready);
//===========================================
// description: generate waddr
wire [dw-1 :0]s_ctrl2sram_write_data;
wire [aw-1 :0]s_ctrl2sram_write_addr;
wire s_ctrl2sram_write_valid;
wire s_ctrl2sramctrl_write_2hsync;

gen_waddr #(
    .aw(aw),
    .dw(dw)
) U_gen_waddr(
    .SYS_CLK    (SYS_CLK),
    .SYS_NRST   (SYS_NRST),

    .pic_size   (pic_size),
    .padding    (padding),
    //.mode       (mode),

    .input_buffer_write_sop         (input_buffer_write_sop),
    .input_buffer_write_data        (input_buffer_write_data),
    .input_buffer_write_valid       (input_buffer_write_valid),
    .input_buffer_write_addr_start  (input_buffer_write_addr_start),
    .input_buffer_write_ready       (input_buffer_write_ready),
    //sram2reg rdy&vlid or first 2 line
    .wbank_update                   (sram2reg_handshake || s_ctrl2sramctrl_write_2hsync),

    .sram_write_data                (s_ctrl2sram_write_data),//o
    .sram_write_addr                (s_ctrl2sram_write_addr),//o
    .sram_write_valid               (s_ctrl2sram_write_valid)//o
);

//===========================================
// description: generate raddr
wire s_register2ctrl_write_resp;
wire s_register_array_full;
wire s_register_array_empty;
wire [aw+1 :0]s_ctrl2sram_read_addr;      
wire s_ctrl2sram_read_valid;     
wire s_ctrl2sync_write_rst;
wire [3:0]s_ctrl2register_write_size; 
wire [2:0]s_ctrl2sync_write_addr_bit; 
wire [3:0]s_ctrl2sync_write_addr_index;
wire s_gen_raddr_line_end;

`ifndef has_mux6_1_no_register_shift
wire s_gen_raddr_req;
wire [7:0]s_ctrl2register_raddr_state;
`endif


wire [3:0]sram_cmd_status;

gen_raddr #(
    .aw(aw)    
)U_gen_raddr (
    .SYS_CLK    (SYS_CLK)                  ,
    .SYS_NRST   (SYS_NRST)                 ,

    .input_buffer_write_sop(input_buffer_write_sop)                  ,
    .input_buffer_write_addr_start(input_buffer_write_addr_start)    ,

    .gen_raddr_start_i (sram2reg_handshake)          ,//when sram2reg_rdy&vld ,start gen raddr of one line 
    .gen_raddr_end_o   (s_gen_raddr_line_end)        ,//fsm state is done

    `ifndef has_mux6_1_no_register_shift
    .gen_raddr_req_o   (s_gen_raddr_req)             ,//o
    .fsm_rsram_state   (s_ctrl2register_raddr_state) ,
    `endif

    .mode_i             (mode)             ,//[0]three direction mode ,[1]line mode stride=1 , [2]line mode stride=2 , [3]full-connected 
    .padding_i          (padding)          ,
    .pic_size_i         (pic_size)         , 

    .sram_cmd_status    (sram_cmd_status)  ,

    .register_array_write_rsp       (s_register2ctrl_write_resp)     ,//regarray receive rdata of 9/3 data
    .register_array_full            (s_register_array_full)          ,

    .sram_cmd_read_addr             (s_ctrl2sram_read_addr)          ,//out raddr
    .sram_cmd_read_valid            (s_ctrl2sram_read_valid)         ,
    .sram_cmd_read_rst              (s_ctrl2sync_write_rst)          ,
    .sram_cmd_read_size             (s_ctrl2register_write_size)     ,//how many data reg_arry should receive

    .register_cmd_write_addr_bit     (s_ctrl2sync_write_addr_bit)     ,
    .register_cmd_write_addr_index   (s_ctrl2sync_write_addr_index)    //for ctrl_mux_1_9


        
);
//===========================================
// description: sram ctrl
//sram interface
wire  [2:0]cen;  
wire  [2:0]wen;  
wire  [dw-1 :0]din0; 
wire  [dw-1 :0]din1; 
wire  [dw-1 :0]din2; 
wire  [aw-1 :0]a0;   
wire  [aw-1 :0]a1;   
wire  [aw-1 :0]a2;   
wire  [dw-1 :0]dout0;
wire  [dw-1 :0]dout1;
wire  [dw-1 :0]dout2;

wire [dw-1 :0]s_sram2register_write_data;
wire s_sram2register_write_valid;


wire s_sram_cmd_end;

reg [5:0]r_cnt_sram2reg_handshake;
always @(posedge SYS_CLK or negedge SYS_NRST) begin
    if (!SYS_NRST)begin
        r_cnt_sram2reg_handshake <= 'b0;
    end
    else begin
        if (input_buffer_write_sop)begin
            r_cnt_sram2reg_handshake <= 'b0;
        end
        else if (sram2reg_handshake)begin
            r_cnt_sram2reg_handshake <= r_cnt_sram2reg_handshake + 1'b1;
        end
    end
end
assign s_sram_cmd_end = mode[3]?
                        s_gen_raddr_line_end :
                        (r_cnt_sram2reg_handshake==((pic_size>>1) - 1'b1 + padding) )&s_gen_raddr_line_end ;
                        

inputbuffer_sram_ctrl #(
    .dw(dw),
    .aw(aw)
)U_inputbuffer_sram_ctrl(
    .SYS_CLK    (SYS_CLK),
    .SYS_NRST   (SYS_NRST),

    .sram_cmd_write_valid   (s_ctrl2sram_write_valid),//wvld*wready
    .sram_cmd_write_data    (s_ctrl2sram_write_data),//i
    .sram_cmd_write_addr    (s_ctrl2sram_write_addr),//i

    .sram_cmd_read_valid    (s_ctrl2sram_read_valid),//rvld
    .sram_cmd_read_addr     (s_ctrl2sram_read_addr),//which bank decided by sram status

    .sram_rsp_read_data     (s_sram2register_write_data),
    .sram_rsp_read_valid    (s_sram2register_write_valid),

    .sram_cmd_status_update (sram2reg_handshake || s_ctrl2sramctrl_write_2hsync),//sram2reg_rdy&vld
    .sram_cmd_start         (input_buffer_write_sop),//data_sop
    .sram_cmd_end           (s_sram_cmd_end),//i read done all 
    .sram_cmd_status        (sram_cmd_status),//o

    //sram interface
    .cen    (cen),
    .wen    (wen),
    .din0   (din0),
    .din1   (din1),
    .din2   (din2),
    .a0     (a0),
    .a1     (a1),
    .a2     (a2),

    .dout0  (dout0),//i
    .dout1  (dout1),
    .dout2  (dout2)
);

sram #(
    .AW(aw) ,
    .DW(dw)
)U_sram (
    .SYS_CLK    (SYS_CLK),
    .SYS_NRST   (SYS_NRST),

    .CEN    (cen),
    .WEN    (wen),

    .A0     (a0),
    .A1     (a1),
    .A2     (a2),
    .DIN0   (din0),
    .DIN1   (din1),
    .DIN2   (din2),

    .DOUT0  (dout0),
    .DOUT1  (dout1),
    .DOUT2  (dout2)    
);
//===========================================
// description: sync register
wire [2:0]s_sync2register_write_addr_bit;
wire [3:0]s_sync2register_write_addr_index;
wire s_sync2register_write_rst;

sync_register U_sync_register
(
    .SYS_CLK        (SYS_CLK),
    .SYS_NRST       (SYS_NRST),

    .raddr_rst_i        (s_ctrl2sync_write_rst),    
    .ctrl_regnum_sel_i  (s_ctrl2sync_write_addr_index),
    .ctrl_regbit_sel_i  (s_ctrl2sync_write_addr_bit),

    .rdata_rst_o        (s_sync2register_write_rst),
    .rdata_regnum_o     (s_sync2register_write_addr_index),
    .rdata_regbit_o     (s_sync2register_write_addr_bit)
);

//===========================================
// description: register array fifo
register_array_fifo #(
    .dw(dw)
)U_register_array_fifo(
    .SYS_CLK    (SYS_CLK),
    .SYS_NRST   (SYS_NRST),

    .pic_size   (pic_size),
    .mode       (mode),
    .padding    (padding),

    //genaddr to register_array
    `ifndef has_mux6_1_no_register_shift
    .fsm_cstate_addr    (s_ctrl2register_raddr_state),//i 7bit
    .gen_addr_req       (s_gen_raddr_req),//i
    `endif

    //fifo write data
    .register_array_write_addr_index    (s_sync2register_write_addr_index),
    .register_array_write_addr_bit      (s_sync2register_write_addr_bit),
    .register_array_write_rst           (s_sync2register_write_rst),

    .register_array_write_data          (s_sram2register_write_data),
    .register_array_write_enable        (s_sram2register_write_valid),//sram_read_enable
    .register_array_write_size          (s_ctrl2register_write_size),//eq 9/3
    .register_array_write_resp          (s_register2ctrl_write_resp),//o
    //fifo read data
    .register_array_read_enable         (register2opu_handshake),//opu_vld&rdy
    .register_array_read_data           (opu1152_data),

    //fifo status
    .register_array_empty               (s_register_array_empty),
    .register_array_full                (s_register_array_full),
    
    //mux1152_1
    .register_array_row_sel             (register_array_row_sel),
    .register_array_row_data            (register_array_row_data)

);
//===========================================
// description: generate ready
gen_ready U_gen_ready
(
    .SYS_CLK    (SYS_CLK),
    .SYS_NRST   (SYS_NRST),

    .input_buffer_write_hsync   (input_buffer_write_hsync),
    .input_buffer_write_sop     (input_buffer_write_sop),

    .pic_size   (pic_size),
    .padding    (padding),
    .mode       (mode),

    .genraddr_end   (s_gen_raddr_line_end),
    //sram to reg
    .register_array_fifo_empty      (s_register_array_empty),
    .input_buffer_write_hsync_eq2   (s_ctrl2sramctrl_write_2hsync),//o

    .sram2reg_valid (sram2reg_valid),
    .sram2reg_ready (sram2reg_ready),
    //data to inputbuffer
    .input_buffer_write_valid   (input_buffer_write_valid),
    .input_buffer_write_ready   (input_buffer_write_ready),
    //register_array to opu
    .register2opu_valid         (register2opu_valid),
    .register2opu_ready         (register2opu_ready)
);

endmodule
