// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\input_buffer_port\icb_input_buffer_top.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-09-16 16:26:12
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-09-17 17:41:34
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module icb_input_buffer_top #(
    parameter AW = 32,
    parameter DW = 32
) (
    input              i_icb_cmd_valid, 
    output             i_icb_cmd_ready, 
    input  [1-1:0]     i_icb_cmd_read, 
    input  [AW-1:0]    i_icb_cmd_addr, 
    input  [DW-1:0]    i_icb_cmd_wdata, 
    input  [DW/8-1:0]  i_icb_cmd_wmask,
    input  [1:0]       i_icb_cmd_size,

    output             i_icb_rsp_valid, 
    input              i_icb_rsp_ready, 
    output             i_icb_rsp_err,
    output [DW-1:0]    i_icb_rsp_rdata, 
    
    input  clk,  
    input  rst_n,
    input  bus_rst_n
);

  wire [AW-1:0]    apb_paddr;
  wire                          apb_pwrite;
  wire                          apb_pselx;
  wire                          apb_penable;
  wire [DW-1:0]         apb_pwdata;
  wire [DW-1:0]         apb_prdata;

sirv_gnrl_icb2apb # (
  .AW   (AW),
  .DW   (DW) 
) u_inputbuffer_apb_icb2apb(
    .i_icb_cmd_valid (i_icb_cmd_valid),
    .i_icb_cmd_ready (i_icb_cmd_ready),
    .i_icb_cmd_addr  (i_icb_cmd_addr ),
    .i_icb_cmd_read  (i_icb_cmd_read ),
    .i_icb_cmd_wdata (i_icb_cmd_wdata),
    .i_icb_cmd_wmask (i_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (i_icb_rsp_valid),
    .i_icb_rsp_ready (i_icb_rsp_ready),
    .i_icb_rsp_rdata (i_icb_rsp_rdata),
    .i_icb_rsp_err   (i_icb_rsp_err),

    .apb_paddr     (apb_paddr  ),
    .apb_pwrite    (apb_pwrite ),
    .apb_pselx     (apb_pselx  ),
    .apb_penable   (apb_penable), 
    .apb_pwdata    (apb_pwdata ),
    .apb_prdata    (apb_prdata ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
);

apb_input_buffer_top U_apb_inpubuffer_0(
    .clk_i(clk),
    .rst_n_i(rst_n),
    .apb_paddr_s(apb_paddr[5:0]),
    .apb_pwrite_s(apb_pwrite),
    .apb_psel_s(apb_pselx),
    .apb_penable_s(apb_penable),
    .apb_pwdata_s(apb_pwdata),
    .apb_prdata_s(apb_prdata),
    .apb_pready_s()
);
    
endmodule