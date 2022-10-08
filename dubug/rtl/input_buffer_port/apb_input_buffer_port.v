// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\input_buffer_port\apb_input_buffer_port.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-09-15 15:43:06
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-10-04 20:59:23
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module apb_input_buffer_port #(
    parameter BUS_AW = 6,
    parameter BUS_DW = 32,
    parameter MAX_CHANNEL_NUM = 128,
    parameter IB_SRAM_AW = 10,
    parameter MAX_COUNTER_VALUE = 32,
    parameter TOKEN_TABLE_ENTRY = 32,
    parameter PROGRAM_TABLE_ENTRY = 32
)(
    input   wire                                clk_i,
    input   wire                                rst_n_i,
            
    input   wire    [BUS_AW-1:0]                apb_paddr_s,
    input   wire                                apb_pwrite_s,
    input   wire                                apb_psel_s,
    input   wire                                apb_penable_s,
    input   wire    [BUS_DW-1:0]                apb_pwdata_s,
    output  reg     [BUS_DW-1:0]                apb_prdata_s,
    output  reg                                 apb_pready_s,
    
    output  wire    [MAX_CHANNEL_NUM-1:0]       inbuf_din_o,
    output  wire                                inbuf_din_vld_o,
    input   wire                                inbuf_din_rdy_i,
    
    output  wire                                inbuf_sop_o,
    output  wire                                inbuf_hsync_o,
    
    output  wire    [IB_SRAM_AW-1:0]            inbuf_start_waddr_o,

    input   wire    [MAX_CHANNEL_NUM*9-1:0]     inbuf_dout_i,
    input   wire                                inbuf_dout_vld_i,
    output  reg                                 inbuf_dout_rdy_o,

    output  wire    [7:0]                       inbuf_pic_size_o,
    output  wire    [3:0]                       inbuf_mode_o,
    output  wire                                inbuf_padding_o,

    output  wire                                inbuf_cmd_vld_o,
    input   wire                                inbuf_cmd_rdy_i,
    output  reg     [10:0]                      inbuf_regarray_row_sel_o,
    input   wire    [7:0]                       inbuf_regarray_row_data_i
);

    localparam CFG_TOEKN_ENTRY = 6'h00;     // W    {token_id, token_value, dst_program} 
    localparam CFG_PROGRAM_ENTRY = 6'h04;   // W    {program_id, program_value, progress_value, picsize, mode, padding}
    localparam RD_TOKEN_ENTRY = 6'h10;      // R
    localparam RD_PROGRAM_ENTRY = 6'h14;    // R

    localparam PACKET_TOKEN_ID = 6'h20;     // W
    localparam PACKET_WORD_DATA = 6'h24;    // W
    localparam REGARRAY_SEL = 6'h28;        // W
    localparam REGARRAY_DATA = 6'h2c;       // W
    

    localparam OPU_INPUT_INDEX = 6'h30;     // W
    localparam OPU_INPUT_PAYLOAD = 6'h34;   // R
    localparam OPU_INPUT_RELEASE = 6'h38;   // W
    localparam OPU_INPUT_STATUS = 6'h3c;    // R

    reg     [$clog2(TOKEN_TABLE_ENTRY)-1:0]     token_id_payload;
    reg                                         token_id_vld;

    reg     [$clog2(TOKEN_TABLE_ENTRY)-1:0]     token_cfg_id;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     token_cfg_counter_value;
    reg     [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   token_cfg_dst_program;
    reg     [$clog2(MAX_CHANNEL_NUM)-1:0]       token_cfg_channel_num;
    reg                                         token_cfg_vld;

    reg                                         program_cfg_vld;
    reg     [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   program_cfg_id;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     program_cfg_counter_value;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     program_cfg_progress_value;
    reg     [7:0]                               program_cfg_picsize;
    reg     [3:0]                               program_cfg_mode;
    reg                                         program_cfg_padding;

    wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     program_value;
    wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     progress_value;
    wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     token_value;


    wire    [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   program_id_payload;
    wire                                        program_id_vld;
    wire                                        program_id_rdy;
    wire                                        program_id_triggerd;


    reg     [7:0]                               wordser_data;
    reg                                         wordser_data_vld;
    wire                                        new_packet;
    wire                                        word2bit_trans_done;
    wire                                        word2bit_packet_received;

    wire    [31:0]                              inbuf_dout32;
    reg     [5:0]                               inbuf_dout32_index;
    wire    [31:0]                              inbuf_dout_unpack   [35:0];

    genvar i;
    generate
        for(i=0; i<36; i=i+1) begin : INBUF_DOUT_UNPACK
            assign inbuf_dout_unpack[i] = inbuf_dout_i[(i+1)*32-1:i*32];
        end
    endgenerate
    assign inbuf_dout32 = inbuf_dout_unpack[inbuf_dout32_index];
    assign inbuf_start_waddr_o = 'h0;

    // write token id payload from PACKET_TOKEN_ID
    always @(posedge clk_i) begin
        if(apb_psel_s && apb_pwrite_s && apb_penable_s && apb_paddr_s == PACKET_TOKEN_ID) begin
            token_id_payload <= apb_pwdata_s[$clog2(TOKEN_TABLE_ENTRY)-1:0];
            token_id_vld <= 1'b1;
        end
        else begin
            token_id_payload <= token_id_payload;
            token_id_vld <= 1'b0;
        end
    end

    // token entry cfg
    always @(posedge clk_i) begin
        if(apb_psel_s && apb_pwrite_s && apb_penable_s && apb_paddr_s == CFG_TOEKN_ENTRY) begin
            token_cfg_counter_value <= apb_pwdata_s[$clog2(MAX_COUNTER_VALUE)-1:0];
            token_cfg_dst_program <= apb_pwdata_s[$clog2(MAX_COUNTER_VALUE)+$clog2(PROGRAM_TABLE_ENTRY)-1:$clog2(MAX_COUNTER_VALUE)];
            token_cfg_channel_num <= apb_pwdata_s[$clog2(MAX_CHANNEL_NUM)+$clog2(MAX_COUNTER_VALUE)+$clog2(PROGRAM_TABLE_ENTRY)-1:$clog2(MAX_COUNTER_VALUE)+$clog2(PROGRAM_TABLE_ENTRY)];
            token_cfg_id <= apb_pwdata_s[$clog2(TOKEN_TABLE_ENTRY)+$clog2(MAX_CHANNEL_NUM)+$clog2(MAX_COUNTER_VALUE)+$clog2(PROGRAM_TABLE_ENTRY)-1:$clog2(MAX_CHANNEL_NUM)+$clog2(MAX_COUNTER_VALUE)+$clog2(PROGRAM_TABLE_ENTRY)];
            token_cfg_vld <= 1'b1;
        end
        else begin
            token_cfg_counter_value <= token_cfg_counter_value;
            token_cfg_dst_program <= token_cfg_dst_program;
            token_cfg_channel_num <= token_cfg_channel_num;
            token_cfg_id <= token_cfg_id;
            token_cfg_vld <= 1'b0;
        end
    end

    // program entry cfg
    always @(posedge clk_i) begin
        if(apb_psel_s && apb_pwrite_s && apb_penable_s && apb_paddr_s == CFG_PROGRAM_ENTRY) begin
            program_cfg_padding <= apb_pwdata_s[0];
            program_cfg_mode <= apb_pwdata_s[4:1];
            program_cfg_picsize <= apb_pwdata_s[12:5];
            program_cfg_progress_value <= apb_pwdata_s[$clog2(MAX_COUNTER_VALUE)+12:13];
            program_cfg_counter_value <= apb_pwdata_s[2*$clog2(MAX_COUNTER_VALUE)+12:$clog2(MAX_COUNTER_VALUE)+13];
            program_cfg_id <= apb_pwdata_s[$clog2(PROGRAM_TABLE_ENTRY)+2*$clog2(MAX_COUNTER_VALUE)+12:2*$clog2(MAX_COUNTER_VALUE)+13];
            program_cfg_vld <= 1'b1;
        end
        else begin
            program_cfg_padding <= program_cfg_padding;
            program_cfg_mode <= program_cfg_mode;
            program_cfg_picsize <= program_cfg_picsize;
            program_cfg_progress_value <= program_cfg_progress_value;
            program_cfg_counter_value <= program_cfg_counter_value;
            program_cfg_id <= program_cfg_id;
            program_cfg_vld <= 1'b0;
        end
    end

    // write reg array row sel
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            inbuf_regarray_row_sel_o <= 'h0;
        end
        else if(apb_psel_s && apb_pwrite_s && apb_penable_s && apb_paddr_s == REGARRAY_SEL) begin
            inbuf_regarray_row_sel_o <= apb_pwdata_s[10:0];
        end
        else begin
            inbuf_regarray_row_sel_o <= inbuf_regarray_row_sel_o;
        end
    end
    // write wordser_data
    always @(posedge clk_i) begin
        if(apb_psel_s && apb_pwrite_s && apb_penable_s && apb_paddr_s == PACKET_WORD_DATA) begin
            wordser_data <= apb_pwdata_s[7:0];
            wordser_data_vld <= 1'b1;
        end
        else begin
            wordser_data_vld <= 1'b0;
            wordser_data <= wordser_data;
        end
    end

    assign new_packet = token_id_vld;

    // inbuf readout logic
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            inbuf_dout_rdy_o <= 1'b0;
        end
        else if(apb_psel_s && apb_pwrite_s && apb_penable_s && apb_paddr_s == OPU_INPUT_RELEASE) begin
            inbuf_dout_rdy_o <= 1'b1;
        end
        else begin
            inbuf_dout_rdy_o <= 1'b0;
        end
    end

    always @(posedge clk_i) begin
        if(apb_psel_s && apb_pwrite_s && apb_penable_s && apb_paddr_s == OPU_INPUT_INDEX) begin
            inbuf_dout32_index <= apb_pwdata_s[5:0];
        end
        else begin
            inbuf_dout32_index <= inbuf_dout32_index;
        end
    end
    
    // read logic
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            apb_prdata_s <= 32'h0;
        end
        else if(apb_psel_s) begin
            case(apb_paddr_s) 
                REGARRAY_DATA : apb_prdata_s <= {24'b0, inbuf_regarray_row_data_i};
                OPU_INPUT_STATUS : apb_prdata_s <= {31'b0, inbuf_dout_vld_i};
                OPU_INPUT_PAYLOAD : apb_prdata_s <= inbuf_dout32;
                RD_TOKEN_ENTRY : begin
                    apb_prdata_s[$clog2(MAX_COUNTER_VALUE)-1:0] <= token_value;
                end
                RD_PROGRAM_ENTRY : begin
                    apb_prdata_s[$clog2(MAX_COUNTER_VALUE)-1:0] <= progress_value;
                    apb_prdata_s[2*$clog2(MAX_COUNTER_VALUE)-1:$clog2(MAX_COUNTER_VALUE)] <= program_value;
                end
                default : apb_prdata_s <= 'h0;
            endcase
        end
    end


    //===========================================
    // description: apb_pready logic, transfer has no wait
        
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            apb_pready_s <= 1'b0;
        end
        else if(apb_penable_s)begin
            apb_pready_s <= 1'b0;
        end
        else if(apb_psel_s) begin
            apb_pready_s <= 1'b1;
        end
    end

    word2bit_trans_unit #(
        .MAX_CHANNEL_NUM(MAX_CHANNEL_NUM)
    ) U_word2bit_0 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .wordser_data_i(wordser_data),           // 8bit
        .wordser_data_vld_i(wordser_data_vld),

        .channel_num_i(token_cfg_channel_num),

        .bitpar_data_o(inbuf_din_o),          // 128 x 1bit
        .bitpar_data_vld_o(inbuf_din_vld_o),
        .bitpar_data_rdy_i(word2bit_bitpar_rdy),

        .new_packet_i(new_packet),
        .packet_received_o(word2bit_packet_received),       //inputBuf has received a packet, token table + 1
        .trans_done_o(word2bit_trans_done)
    );

    token_table_ctrl #(
        .MAX_COUNTER_VALUE(MAX_COUNTER_VALUE),
        .TOKEN_TABLE_ENTRY(TOKEN_TABLE_ENTRY),
        .PROGRAM_TABLE_ENTRY(PROGRAM_TABLE_ENTRY)
    ) U_token_table_ctrl_0(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .token_id_payload_i(token_id_payload),
        .token_id_vld_i(token_id_vld),
        .token_id_rdy_o(token_id_rdy),

        .token_value_o(token_value),

        // token table config port
        .token_cfg_id_i(token_cfg_id),
        .token_cfg_counter_value_i(token_cfg_counter_value),
        .token_cfg_dst_program_i(token_cfg_dst_program),
        .token_cfg_vld_i(token_cfg_vld),

        .program_id_vld_o(program_id_vld),            // 指示本次访问有效
        .program_id_rdy_i(program_id_rdy),
        .program_id_payload_o(program_id_payload),       // 本次访问的index
        .program_id_triggerd_o(program_id_triggerd)      // 本次访问是否触发program计数器加一，即hsync
    );

    program_table_ctrl #(
        .MAX_COUNTER_VALUE(MAX_COUNTER_VALUE),
        .PROGRAM_TABLE_ENTRY(PROGRAM_TABLE_ENTRY)
    ) dut (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .program_id_rdy_o(program_id_rdy),
        .program_id_vld_i(program_id_vld),            // 指示本次访问有效
        .program_id_payload_i(program_id_payload),       // 本次访问的index
        .program_id_triggerd_i(program_id_triggerd),      // 本次访问是否触发program计数器加一，即hsync

        .program_value_o(program_value),
        .progress_value_o(progress_value),

        .program_cfg_id_i(program_cfg_id), 
        .program_cfg_vld_i(program_cfg_vld),
        .program_cfg_counter_value_i(program_cfg_counter_value),
        .program_cfg_progress_value_i(program_cfg_progress_value),
        .program_cfg_picsize_i(program_cfg_picsize),
        .program_cfg_mode_i(program_cfg_mode),
        .program_cfg_padding_i(program_cfg_padding),

        .word2bit_trans_done_i(word2bit_trans_done),
        .word2bit_packet_received_i(word2bit_packet_received),

        .inbuf_pic_size_o(inbuf_pic_size_o),
        .inbuf_mode_o(inbuf_mode_o),
        .inbuf_padding_o(inbuf_padding_o),

        .inbuf_sop_o(inbuf_sop_o),
        .inbuf_hsync_o(inbuf_hsync_o),
        .inbuf_cmd_vld_o(inbuf_cmd_vld_o),
        .inbuf_cmd_rdy_i(inbuf_cmd_rdy_i),

        .inbuf_din_rdy_i(inbuf_din_rdy_i),
        .word2bit_bitpar_rdy_o(word2bit_bitpar_rdy)
    );


endmodule