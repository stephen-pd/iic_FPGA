module gen_waddr #(
    parameter aw = 10,
    parameter dw = 128
) (
    input   SYS_CLK,
    input   SYS_NRST,

    input   [5:0]pic_size,
    input   padding,
    //input   [3:0]mode,

    input   input_buffer_write_sop,
    input   [dw-1 :0]input_buffer_write_data,
    input   input_buffer_write_valid,
    input   [aw-1 :0]input_buffer_write_addr_start,
    input   input_buffer_write_ready,
    //sram2reg rdy&vlid or first 2line
    input   wbank_update,

    output  [dw-1 :0]sram_write_data,
    output  [aw-1 :0]sram_write_addr,
    output  sram_write_valid
);

    reg [aw-1 :0]r_waddr;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_waddr <= 'b0;
        end
        else begin
            if (input_buffer_write_sop)begin
                r_waddr <= input_buffer_write_addr_start + (padding ? pic_size<<3 : 'b0);
            end
            else if (wbank_update)begin
                r_waddr <= input_buffer_write_addr_start;
            end
            else if (input_buffer_write_ready & input_buffer_write_valid)begin
                r_waddr <= r_waddr + 1'b1;
            end
        end
    end

    assign sram_write_addr = r_waddr;
    assign sram_write_data = input_buffer_write_data;
    assign sram_write_valid = input_buffer_write_valid & input_buffer_write_ready;
    
endmodule