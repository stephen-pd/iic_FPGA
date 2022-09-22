// +FHEADER ==================================================
// FilePath       : \sr\top_mux.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-24 21:05:03
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-08-24 22:17:02
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module top_mux #(
    parameter DW = 2;
)(
    input SYS_CLK,
    input [2:0]CTRL,

    input [DW-1 : 0]   i_0,
    input [DW-1 : 0]   i_1,
    input [DW-1 : 0]   i_2,
    input [DW-1 : 0]   i_3,
    input [DW-1 : 0]   i_4,
    input [DW-1 : 0]   i_5,
    input [DW-1 : 0]   i_6,
    input [DW-1 : 0]   i_7,
    input [DW-1 : 0]   i_8,

    output reg [DW-1 : 0]   o_0,
    output reg [DW-1 : 0]   o_1,
    output reg [DW-1 : 0]   o_2,
    output reg [DW-1 : 0]   o_3,
    output reg [DW-1 : 0]   o_4,
    output reg [DW-1 : 0]   o_5,
    output reg [DW-1 : 0]   o_6,
    output reg [DW-1 : 0]   o_7,
    output reg [DW-1 : 0]   o_8

);

    reg [DW-1 : 0]   r_i_0;
    reg [DW-1 : 0]   r_i_1;
    reg [DW-1 : 0]   r_i_2;
    reg [DW-1 : 0]   r_i_3;
    reg [DW-1 : 0]   r_i_4;
    reg [DW-1 : 0]   r_i_5;
    reg [DW-1 : 0]   r_i_6;
    reg [DW-1 : 0]   r_i_7;
    reg [DW-1 : 0]   r_i_8;

    wire [DW-1 : 0]   w_o_0;
    wire [DW-1 : 0]   w_o_1;
    wire [DW-1 : 0]   w_o_2;
    wire [DW-1 : 0]   w_o_3;
    wire [DW-1 : 0]   w_o_4;
    wire [DW-1 : 0]   w_o_5;
    wire [DW-1 : 0]   w_o_6;
    wire [DW-1 : 0]   w_o_7;
    wire [DW-1 : 0]   w_o_8;

    always @(posedge SYS_CLK) begin
        r_i_0 <= i_0   ;
        r_i_1 <= i_1   ;
        r_i_2 <= i_2   ;
        r_i_3 <= i_3   ;
        r_i_4 <= i_4   ;
        r_i_5 <= i_5   ;
        r_i_6 <= i_6   ;
        r_i_7 <= i_7   ;
        r_i_8 <= i_8   ;
    end

    always @(posedge SYS_CLK) begin
        o_0 <= w_o_0   ;
        o_1 <= w_o_1   ;
        o_2 <= w_o_2   ;
        o_3 <= w_o_3   ;
        o_4 <= w_o_4   ;
        o_5 <= w_o_5   ;
        o_6 <= w_o_6   ;
        o_7 <= w_o_7   ;
        o_8 <= w_o_8   ;
    end

    mux #(
        .DW(DW)
    )U_mux_0(
    .ctrl        ( CTRL),
    .reg2mux_i_0 ( r_i_0),
    .reg2mux_i_1 ( r_i_1),
    .reg2mux_i_2 ( r_i_2),
    .reg2mux_i_3 ( r_i_3),
    .reg2mux_i_4 ( r_i_4),
    .reg2mux_i_5 ( r_i_5),
    .reg2mux_i_6 ( r_i_6),
    .reg2mux_i_7 ( r_i_7),
    .reg2mux_i_8 ( r_i_8),
    .mux2opu_o_0 ( w_o_0),
    .mux2opu_o_1 ( w_o_1),
    .mux2opu_o_2 ( w_o_2),
    .mux2opu_o_3 ( w_o_3),
    .mux2opu_o_4 ( w_o_4),
    .mux2opu_o_5 ( w_o_5),
    .mux2opu_o_6 ( w_o_6),
    .mux2opu_o_7 ( w_o_7),
    .mux2opu_o_8 ( w_o_8)

);
endmodule
