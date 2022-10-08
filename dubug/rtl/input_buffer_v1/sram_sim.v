module sram_sim #(
    parameter AW = 10  ,
    parameter DW = 128 
)(    
    input             clk       ,
    input      [ AW -1:0] addr  ,
    input      [ DW -1:0] din   ,
    input             ce        ,
    input             we        ,
    output     [ DW -1:0] dout  
);

localparam MEM_DEPTH = 1 << AW  ;

reg [DW-1:0] mem[MEM_DEPTH-1:0];  //mem是8*16的寄存器数组
reg [DW-1:0] r_dout            ; 

// synopsys_translate_off
assign dout   = r_dout          ;
integer i;
initial begin
    for(i=0; i<MEM_DEPTH;i=i+1) begin
        mem[i] = 'b0;
    end
end
// synopsys_translate_on

always @(posedge clk) begin
    if(ce & we) begin
        mem[addr] = din;
    end
end

always @(posedge clk) begin
    if(ce && (!we)) begin
        r_dout <= mem[addr];
    end
end

endmodule
