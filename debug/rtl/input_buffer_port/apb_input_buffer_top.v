// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\input_buffer_port\apb_input_buffer_top.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-09-16 14:53:41
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-09-26 17:10:12
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module apb_input_buffer_top #(
    parameter BUS_AW = 6,
    parameter BUS_DW = 32,
    parameter MAX_CHANNEL_NUM = 128,
    parameter IB_SRAM_AW = 10,
    parameter MAX_COUNTER_VALUE = 32,
    parameter TOKEN_TABLE_ENTRY = 32,
    parameter PROGRAM_TABLE_ENTRY = 32
) (
    input   wire                                clk_i,
    input   wire                                rst_n_i,
            
    input   wire    [BUS_AW-1:0]                apb_paddr_s,
    input   wire                                apb_pwrite_s,
    input   wire                                apb_psel_s,
    input   wire                                apb_penable_s,
    input   wire    [BUS_DW-1:0]                apb_pwdata_s,
    output  wire    [BUS_DW-1:0]                apb_prdata_s,
    output  wire                                apb_pready_s
);
    wire    [MAX_CHANNEL_NUM-1:0]       inbuf_din;
    wire                                inbuf_din_vld;
    wire                                inbuf_din_rdy;
    wire                                inbuf_sop;
    wire                                inbuf_hsync;
    wire    [IB_SRAM_AW-1:0]            inbuf_start_waddr;
    wire    [MAX_CHANNEL_NUM*9-1:0]     inbuf_dout;
    wire                                inbuf_dout_vld;
    wire                                inbuf_dout_rdy;
    wire    [7:0]                       inbuf_pic_size;
    wire    [3:0]                       inbuf_mode;
    wire                                inbuf_padding;
    wire                                inbuf_cmd_vld;
    wire                                inbuf_cmd_rdy;

    apb_input_buffer_port #(
        .BUS_AW(BUS_AW),
        .BUS_DW(BUS_DW),
        .MAX_CHANNEL_NUM(MAX_CHANNEL_NUM),
        .IB_SRAM_AW(IB_SRAM_AW),
        .MAX_COUNTER_VALUE(MAX_COUNTER_VALUE),
        .TOKEN_TABLE_ENTRY(TOKEN_TABLE_ENTRY),
        .PROGRAM_TABLE_ENTRY(PROGRAM_TABLE_ENTRY)
    ) U_apb_input_buffer_port_0(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .apb_paddr_s(apb_paddr_s),
        .apb_pwrite_s(apb_pwrite_s),
        .apb_psel_s(apb_psel_s),
        .apb_penable_s(apb_penable_s),
        .apb_pwdata_s(apb_pwdata_s),
        .apb_prdata_s(apb_prdata_s),
        .apb_pready_s(apb_pready_s),
        .inbuf_din_o(inbuf_din),
        .inbuf_din_vld_o(inbuf_din_vld),
        .inbuf_din_rdy_i(inbuf_din_rdy),
        .inbuf_sop_o(inbuf_sop),
        .inbuf_hsync_o(inbuf_hsync),
        .inbuf_start_waddr_o(inbuf_start_waddr),
        .inbuf_dout_i(inbuf_dout),
        .inbuf_dout_vld_i(inbuf_dout_vld),
        .inbuf_dout_rdy_o(inbuf_dout_rdy),
        .inbuf_pic_size_o(inbuf_pic_size),
        .inbuf_mode_o(inbuf_mode),
        .inbuf_padding_o(inbuf_padding),
        .inbuf_cmd_vld_o(inbuf_cmd_vld),
        .inbuf_cmd_rdy_i(inbuf_cmd_rdy)
    );

    top #(
        .AW(IB_SRAM_AW),
        .DW(MAX_CHANNEL_NUM)
    )U_input_buffer_top_0 (
        .SYS_CLK    (clk_i    ),
        .SYS_NRST    (rst_n_i  ),

        .DATA       (inbuf_din       ),
        .DATA_VLD   (inbuf_din_vld   ),
        .DATA_HSYNC (inbuf_hsync ),
        .DATA_SOP   (inbuf_sop   ),

        .WRADDR_START   (inbuf_start_waddr ),

        .SRAM2REG_VLD   (inbuf_cmd_vld),
        .SRAM2REG_RDY   (inbuf_cmd_rdy),

        .OPU_1152_RDY   (inbuf_dout_rdy),
        .OPU_1152_VLD   (inbuf_dout_vld),
        .PIC_SIZE       (inbuf_pic_size ),
        .PADDING        (inbuf_padding  ),
        .MODE           (inbuf_mode     ),

        .WREADY         (inbuf_din_rdy   ),

        .OPU_1152       (inbuf_dout ),
        .CTRL_MUX_1152_1(11'b0        ), 
        .REG_ARRAY_ROW  (),
        .SRAM_STATUS    ()
    );
    
endmodule