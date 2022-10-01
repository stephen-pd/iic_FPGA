// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\utils\table.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-09-14 16:28:39
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-09-16 15:49:24
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module table_symbol #(
    parameter DEPTH = 32,
    parameter WIDTH = 32
) (
    input   wire                            clk,
    input   wire                            we,
    input   wire    [$clog2(DEPTH)-1:0]     addr,
    input   wire    [WIDTH-1:0]             din,
    output  reg     [WIDTH-1:0]             dout
);

reg     [WIDTH-1:0]     ram     [DEPTH-1:0];

always @(posedge clk) begin
    if(we) begin
        ram[addr] <= din;
    end
end

always @(posedge clk) begin
    dout <= ram[addr];
end
    
endmodule