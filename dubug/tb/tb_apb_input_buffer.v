// +FHEADER ==================================================
// FilePath       : \MPW2022_11\tb\tb_apb_input_buffer.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-08-27 20:45:50
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-09-26 17:11:03
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
`timescale 1ps/1ps
module tb_apb_input_buffer;

    localparam CLK_HALF_PER = 1;
    localparam AW = 6;
    localparam DW = 32;

    parameter BUS_AW = 6;
    parameter BUS_DW = 32;
    parameter MAX_CHANNEL_NUM = 128;
    parameter IB_SRAM_AW = 10;
    parameter MAX_COUNTER_VALUE = 32;
    parameter TOKEN_TABLE_ENTRY = 32;
    parameter PROGRAM_TABLE_ENTRY = 32;

    localparam CHANNEL = 128;

    reg                     clk;
    reg                     rst_n;

    reg     [AW-1:0]        paddr;
    reg                     pwrite;
    reg                     psel;
    reg                     penable;
    reg     [DW-1:0]        pwdata;
    wire    [DW-1:0]        prdata;
    wire                    pready;

    reg                     cfg_done;


    reg     [$clog2(TOKEN_TABLE_ENTRY)-1:0]     token_cfg_id;
    reg signed     [$clog2(MAX_COUNTER_VALUE)-1:0]     token_cfg_counter_value;
    reg     [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   token_cfg_dst_program;
    reg     [$clog2(MAX_CHANNEL_NUM)-1:0]       token_cfg_channel_num;

    reg     [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   program_cfg_id;
    reg signed     [$clog2(MAX_COUNTER_VALUE)-1:0]     program_cfg_counter_value;
    reg signed     [$clog2(MAX_COUNTER_VALUE)-1:0]     program_cfg_progress_value;
    reg     [7:0]                               program_cfg_picsize;
    reg     [3:0]                               program_cfg_mode;
    reg                                         program_cfg_padding;

    reg     [31:0]      opu_din     [35:0];

    integer i;
    genvar j;
    integer col_offset;
    integer rd_1152_offset;

    localparam CFG_TOEKN_ENTRY = 6'h00;     // W    {token_id, token_value, dst_program} 
    localparam CFG_PROGRAM_ENTRY = 6'h04;   // W    {program_id, program_value, progress_value, picsize, mode, padding}
    localparam RD_TOKEN_ENTRY = 6'h10;      // R
    localparam RD_PROGRAM_ENTRY = 6'h14;    // R

    localparam PACKET_TOKEN_ID = 6'h20;      // W
    localparam PACKET_WORD_DATA = 6'h24;     // W
    

    localparam OPU_INPUT_INDEX = 6'h30;     // W
    localparam OPU_INPUT_PAYLOAD = 6'h34;   // R
    localparam OPU_INPUT_RELEASE = 6'h38;   // W
    localparam OPU_INPUT_STATUS = 6'h3c;    // R

    // gen clk
    always # CLK_HALF_PER clk = ~clk;

    // gen rst & sim_time_out
    initial begin
        clk = 0;
        rst_n = 0;
        repeat(3) @(posedge clk);

        rst_n = 1;
        repeat(1000000) @(posedge clk);
        $display("**** Sim Time Out ****");
        $stop();
    end

    // gen waveform
    initial begin
        $dumpfile("tb_apb_input_buffer.vcd");
        $dumpvars(0, tb_apb_input_buffer);
    end

    initial begin
        cfg_done = 0;
        wait(rst_n);
        token_cfg_id = 'h0;
        token_cfg_counter_value = -7;
        token_cfg_dst_program = 'h1;
        token_cfg_channel_num = CHANNEL - 1;

        APB_WRITE(CFG_TOEKN_ENTRY, {token_cfg_id, token_cfg_channel_num, token_cfg_dst_program, token_cfg_counter_value});

        program_cfg_id = 'h1;
        program_cfg_counter_value = -2;
        program_cfg_progress_value = -3;
        program_cfg_picsize = 8;
        program_cfg_mode = 1;
        program_cfg_padding = 1;
        APB_WRITE(CFG_PROGRAM_ENTRY, {program_cfg_id, program_cfg_counter_value, program_cfg_progress_value, program_cfg_picsize, program_cfg_mode, program_cfg_padding});
        cfg_done = 1;
    end

    initial begin
        wait(cfg_done);
        repeat(2) begin
            //first elements is tokenid , second is col_size, third is index of col_size
            WRITE_COLUMN(0, 8, 0);  // col 1
            WRITE_COLUMN(0, 8, 1);  // col 2
            WRITE_COLUMN(0, 8, 2);  // col 3
            READ_COLUMN(8);
    
            WRITE_COLUMN(0, 8, 3);  // col 4
            WRITE_COLUMN(0, 8, 4);  // col 5
            READ_COLUMN(8);
    
            WRITE_COLUMN(0, 8, 5);  // col 6
            WRITE_COLUMN(0, 8, 6);  // col 7
            READ_COLUMN(8);
    
            WRITE_COLUMN(0, 8, 7);  // col 8
            READ_COLUMN(8);
        end

        $stop();
    end



    // gen stimulus

    task WRITE_COLUMN(
        input   [$clog2(TOKEN_TABLE_ENTRY)-1:0] token_id,
        input   [$clog2(MAX_COUNTER_VALUE)-1:0] col_size,
        input   [7:0]                           din
    );
    begin
        col_offset = 0;
        repeat(col_size) begin
            APB_WRITE(PACKET_TOKEN_ID, token_id);
            repeat(CHANNEL) begin
                APB_WRITE(PACKET_WORD_DATA, din+col_offset);
            end
            col_offset = col_offset + 1;
            repeat(32) @(posedge clk);
        end
    end
    endtask

    task READ_COLUMN(
        input   [$clog2(MAX_COUNTER_VALUE)-1:0] col_size
    );
        repeat(col_size) begin
            APB_READ(OPU_INPUT_STATUS);
            while(!prdata[0]) begin
                APB_READ(OPU_INPUT_STATUS);
            end
            
            repeat(8) begin
                rd_1152_offset = 0;
                repeat(36) begin
                    APB_WRITE(OPU_INPUT_INDEX, rd_1152_offset);
                    APB_READ(OPU_INPUT_PAYLOAD);
                    opu_din[rd_1152_offset] = prdata;
                    rd_1152_offset = rd_1152_offset + 1;
                end
                APB_WRITE(OPU_INPUT_RELEASE, 1);
            end
        end
        
    endtask

    task APB_WRITE(
        input   [AW-1:0]    addr,
        input   [DW-1:0]    wdata
    );
    begin
        psel = 0;
        penable = 0;
        pwrite = 1;
        paddr = addr;
        pwdata = wdata;
        @(posedge clk);
        psel = 1;
        @(posedge clk);
        penable = 1;
        wait(pready);
        @(posedge clk);
        penable = 0;
        psel = 0;
        pwrite = 0;
    end
    endtask

    task APB_READ(
        input   [AW-1:0]    addr
    );
    begin
        psel = 0;
        penable = 0;
        pwrite = 0;
        paddr = addr;
        @(posedge clk);
        psel = 1;
        @(posedge clk);
        penable = 1;
        wait(pready);
        @(posedge clk);
        penable = 0;
        psel = 0;
        pwrite = 0;
    end
    endtask

apb_input_buffer_top #(
    .BUS_AW(BUS_AW),
    .BUS_DW(BUS_DW),
    .MAX_CHANNEL_NUM(MAX_CHANNEL_NUM),
    .IB_SRAM_AW(IB_SRAM_AW),
    .MAX_COUNTER_VALUE(MAX_COUNTER_VALUE),
    .TOKEN_TABLE_ENTRY(TOKEN_TABLE_ENTRY),
    .PROGRAM_TABLE_ENTRY(PROGRAM_TABLE_ENTRY)
)DUT(
    .clk_i(clk),
    .rst_n_i(rst_n),
    .apb_paddr_s(paddr),
    .apb_pwrite_s(pwrite),
    .apb_psel_s(psel),
    .apb_penable_s(penable),
    .apb_pwdata_s(pwdata),
    .apb_prdata_s(prdata),
    .apb_pready_s(pready)
);


    
endmodule