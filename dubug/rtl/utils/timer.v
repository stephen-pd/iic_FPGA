// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\utils\timer.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-08-27 19:51:00
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-08-27 21:21:41
// Description    : 32bit timer， tick when timer_value bigger than cmp_value
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module timer(
    input   wire                clk_i,
    input   wire                rst_i,
    input   wire                clr_i,
    input   wire                ena_i,

    input   wire    [31:0]      cmp_value_i,

    output  reg     [31:0]      value_o,
    output  reg                 tick_o
);

always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        value_o <= 32'h0;
    end
    else if(clr_i) begin
        value_o <= 32'h0;
    end
    else if(ena_i) begin
        value_o <= value_o + 1'b1;
    end
    else begin
        value_o <= value_o;
    end
end

always @(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        tick_o <= 1'b0;
    end
    else if(clr_i) begin
        tick_o <= 1'b0;
    end
    else if(value_o == cmp_value_i) begin
        tick_o <= 1'b1;
    end
    else begin
        tick_o <= tick_o;
    end
end
    
endmodule