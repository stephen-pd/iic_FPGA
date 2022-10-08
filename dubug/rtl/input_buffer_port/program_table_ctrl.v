// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\input_buffer_port\program_table_ctrl.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-09-22 14:20:16
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-10-07 13:34:56
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module program_table_ctrl #(
    parameter MAX_COUNTER_VALUE = 32,
    parameter PROGRAM_TABLE_ENTRY = 32
) (
    input   wire                                        clk_i,
    input   wire                                        rst_n_i,

    output  reg                                         program_id_rdy_o,
    input   wire                                        program_id_vld_i,            // 指示本次访问有效
    input   wire    [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   program_id_payload_i,       // 本次访问的index
    input   wire                                        program_id_triggerd_i,      // 本次访问是否触发program计数器加一，即hsync

    output  wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     program_value_o,
    output  wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     progress_value_o,

    input   wire    [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   program_cfg_id_i, 
    input   wire                                        program_cfg_vld_i,
    input   wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     program_cfg_counter_value_i,
    input   wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     program_cfg_progress_value_i,
    input   wire    [7:0]                               program_cfg_picsize_i,
    input   wire    [3:0]                               program_cfg_mode_i,
    input   wire                                        program_cfg_padding_i,

    input   wire                                        word2bit_trans_done_i,
    input   wire                                        word2bit_packet_received_i,

    output  wire    [7:0]                               inbuf_pic_size_o,
    output  wire    [3:0]                               inbuf_mode_o,
    output  wire                                        inbuf_padding_o,

    output  wire                                        inbuf_sop_o,
    output  wire                                        inbuf_hsync_o,
            
    output  reg                                         inbuf_cmd_vld_o,
    input   wire                                        inbuf_cmd_rdy_i,

    input   wire                                        inbuf_din_rdy_i,
    output  wire                                        word2bit_bitpar_rdy_o
);
    // | sop_locked | program_counter | program_counter_init |progress_counter | pic_size | mode | padding |
    localparam PROGRAM_TABLE_WIDTH = $clog2(MAX_COUNTER_VALUE) + $clog2(MAX_COUNTER_VALUE) + $clog2(MAX_COUNTER_VALUE) + $clog2(MAX_COUNTER_VALUE) + 14;
    `define PADDING_RAGE            0:0
    `define MODE_RAGE               4:1
    `define PICSIZE_RAGE            12:5
    `define PROGRESS_INIT_RANGE     $clog2(MAX_COUNTER_VALUE)+12:13
    `define PROGRESS_VALUE_RANGE    2*$clog2(MAX_COUNTER_VALUE)+12:$clog2(MAX_COUNTER_VALUE)+13
    `define PROGRAM_INIT_RANGE      3*$clog2(MAX_COUNTER_VALUE)+12:2*$clog2(MAX_COUNTER_VALUE)+13
    `define PROGRAM_VALUE_RANGE     4*$clog2(MAX_COUNTER_VALUE)+12:3*$clog2(MAX_COUNTER_VALUE)+13
    `define SOP_LOCKED_RANGE        4*$clog2(MAX_COUNTER_VALUE)+13:4*$clog2(MAX_COUNTER_VALUE)+13
    

    localparam IDLE = 3'h0;
    localparam FETCH = 3'h1;
    localparam UPDATE = 3'h2;
    localparam BROAD_SOP = 3'h3;
    localparam BROAD_DATA = 3'h4;
    localparam BROAD_HSYNC = 3'h5;
    localparam BROAD_CMD = 3'h6;

    localparam USE_PADDING = 1'b1;
    localparam USE_FC = 4'h8;

    wire                                            program_id_fire;
    wire                                            inbuf_cmd_fire;

    reg                                             skip_entry_update;
    reg     [$clog2(PROGRAM_TABLE_ENTRY)-1:0]       current_program;
    reg                                             current_program_trigger;
    reg                                             program_locked;

    reg                                             update_value_vld;
    reg                                             update_value_vld_d1;

    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]         program_value;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]         program_value_init;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]         progress_value;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]         progress_value_init;
    reg     [7:0]                                   inbuf_pic_size;
    reg     [3:0]                                   inbuf_mode;
    reg                                             inbuf_padding;

    wire    [PROGRAM_TABLE_WIDTH-1:0]               program_table_entry;

    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]         program_value_update;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]         progress_value_update;


    reg                                             last_column;
    reg                                             first_column;

    wire                                            program_table_we;
    wire    [$clog2(PROGRAM_TABLE_ENTRY)-1:0]       program_table_index;
    wire    [PROGRAM_TABLE_WIDTH-1:0]               program_table_entry_update;

    reg     [2:0]       fsm_cstate;
    reg     [2:0]       fsm_nstate;

    reg                 rd_entry_vld;   
    reg                 rd_entry_vld_d1;
    reg                 sop;     
    reg                 sop_locked;
    reg                 sop_locked_update;

    assign program_id_fire = program_id_vld_i && program_id_rdy_o;
    assign inbuf_cmd_fire = inbuf_cmd_rdy_i && inbuf_cmd_vld_o;

    always @(posedge clk_i) begin
        if(program_id_fire) begin
            current_program <= program_id_payload_i;
            current_program_trigger <= program_id_triggerd_i;
            program_locked <= 1'b1;
        end
        else begin
            current_program <= current_program;
            current_program_trigger <= current_program_trigger;
            program_locked <= 1'b0;
        end
    end

    always @(posedge clk_i) begin
        rd_entry_vld <= program_locked;
        rd_entry_vld_d1 <= rd_entry_vld;
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            skip_entry_update <= 1'b0;
        end
        else if(program_id_fire) begin  // 若当前id与上一次id相同，且不trigger，则跳过读写table
            if(current_program == program_id_payload_i && !program_id_triggerd_i) begin
                skip_entry_update <= 1'b1;
            end
        end
        else if(fsm_cstate == IDLE) begin
            skip_entry_update <= 1'b0;
        end
        else begin
            skip_entry_update <= skip_entry_update;
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            fsm_cstate <= IDLE;
        end
        else begin
            fsm_cstate <= fsm_nstate;
        end
    end

    always @(*) begin
        case(fsm_cstate)
            IDLE : begin
                if(program_id_fire) begin
                    fsm_nstate = FETCH;
                end
            end
            FETCH : begin
                /*
                if(skip_entry_update) begin
                    fsm_nstate = BROAD_DATA;
                end
                else if(rd_entry_vld) begin
                    fsm_nstate = UPDATE;
                end
                */
                if(rd_entry_vld) begin
                    fsm_nstate = UPDATE;
                end
            end
            UPDATE : begin
                if(word2bit_trans_done_i && sop) begin
                    fsm_nstate = BROAD_SOP;
                end
                else if(word2bit_trans_done_i) begin
                    fsm_nstate = BROAD_DATA;
                end
            end
            BROAD_SOP : begin
                fsm_nstate = BROAD_DATA;
            end
            BROAD_DATA : begin
                /*
                if(word2bit_packet_received_i && !skip_entry_update) begin
                    fsm_nstate = BROAD_HSYNC;
                end
                else if(skip_entry_update) begin
                    fsm_nstate = IDLE;
                end
                */
                if(word2bit_packet_received_i) begin
                    fsm_nstate = BROAD_HSYNC;
                end
            end
            BROAD_HSYNC : begin
                if(program_value == 'h0 && current_program_trigger) begin
                    fsm_nstate = BROAD_CMD;
                end
                else begin
                    fsm_nstate = IDLE;
                end
                
            end
            BROAD_CMD : begin
                if(inbuf_cmd_fire) begin
                    fsm_nstate = IDLE;
                end
            end
            default : fsm_nstate = IDLE;
        endcase
    end

    // access program table, stored in local register
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            program_value <= 'h0;
            program_value_init <= 'h0;
            progress_value <= 'h0;
            progress_value_init <= 'h0;
            inbuf_mode <= 'h0;
            inbuf_padding <= 'h0;
            inbuf_pic_size <= 'h0;
        end
        else if(fsm_cstate == FETCH) begin
            program_value <= program_table_entry[`PROGRAM_VALUE_RANGE];
            program_value_init <= program_table_entry[`PROGRAM_INIT_RANGE];
            progress_value <= program_table_entry[`PROGRESS_VALUE_RANGE];
            progress_value_init <= program_table_entry[`PROGRESS_INIT_RANGE];
            inbuf_mode <= program_table_entry[`MODE_RAGE];
            inbuf_padding <= program_table_entry[`PADDING_RAGE];
            inbuf_pic_size <= program_table_entry[`PICSIZE_RAGE];
        end
        else begin
            program_value <= program_value;
            program_value_init <= program_value_init;
            progress_value <= progress_value;
            progress_value_init <= progress_value_init;
            inbuf_mode <= inbuf_mode;
            inbuf_padding <= inbuf_padding;
            inbuf_pic_size <= inbuf_pic_size;
        end
    end

    assign program_value_o = program_value;
    assign progress_value_o = progress_value;
    assign inbuf_mode_o = inbuf_mode;
    assign inbuf_padding_o = inbuf_padding;
    assign inbuf_pic_size_o = inbuf_pic_size;

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            last_column <= 1'b0;
            first_column <= 1'b0;
        end
        else if(rd_entry_vld_d1) begin
            last_column <= & progress_value;    // progress_value == -1
            //first_column <= !(| progress_value);   // progress_value == 0
            first_column <= (progress_value == 'h0 || inbuf_mode == USE_FC);
        end
        else begin
            last_column <= last_column;
            first_column <= first_column;
        end
    end


    // update 
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            update_value_vld <= 1'b0;
        end
        else if(fsm_cstate == BROAD_DATA) begin
            update_value_vld <= 1'b0;
        end
        else if(fsm_cstate == UPDATE) begin
            update_value_vld <= 1'b1;
        end
        else begin
            update_value_vld <= update_value_vld;
        end
    end

    always @(posedge clk_i) begin
        update_value_vld_d1 <= update_value_vld;
    end

    // program_table update
    always @(posedge clk_i) begin
        if(fsm_cstate == UPDATE && !update_value_vld_d1 && current_program_trigger) begin
            if(program_value == 'h0 && (inbuf_padding == USE_PADDING) && last_column) begin
                program_value_update <= 'h0;    //padding时,最后一次计算仅收1列
            end
            else if(program_value =='h0 && first_column) begin
                program_value_update <= program_value_init;
            end
            else if(program_value == 'h0) begin
                program_value_update <= {($clog2(MAX_COUNTER_VALUE)){1'b1}};    //-1，默认情况下每收2列触发一次每收2列触发一次
            end
            else begin
                program_value_update <= program_value + 1'b1;
            end
        end
        else if(fsm_cstate == UPDATE && !update_value_vld_d1) begin
            program_value_update <= program_value;
        end
        else begin
            program_value_update <= program_value_update;
        end
    end

    always @(posedge clk_i) begin
        if(fsm_cstate == UPDATE && !update_value_vld_d1 && current_program_trigger) begin
            if(inbuf_mode == USE_FC) begin
                progress_value <= progress_value_init;  //全连接仅需1次progress，但设为0将无法正确产生sop    
            end
            else if(program_value == 'h0 && progress_value == 'h0) begin
                progress_value_update <= progress_value_init;
            end
            else if(program_value == 'h0) begin
                progress_value_update <= progress_value + 1'b1;
            end
            else begin
                progress_value_update <= progress_value;
            end
        end
        else if(fsm_cstate == UPDATE && !update_value_vld_d1) begin
            progress_value_update <= progress_value;
        end
        else begin
            progress_value_update <= progress_value_update;
        end
    end

    // Broad SoP Logic
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            sop <= 1'b0;
        end
        else if(fsm_cstate == UPDATE) begin
            if(progress_value == progress_value_init && !sop_locked) begin
                sop <= 1'b1;
            end
            else begin
                sop <= 1'b0;
            end
        end
        else begin
            sop <= sop;
        end
    end

    assign inbuf_sop_o = (fsm_cstate == BROAD_SOP) ? sop : 0;

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            sop_locked <= 1'b0;
        end
        else if(fsm_cstate == FETCH) begin
            sop_locked <= program_table_entry[`SOP_LOCKED_RANGE];
        end
        else if(progress_value == 'h0) begin
            sop_locked <= 1'b0;
        end
        /*
        else if(current_program_trigger && inbuf_mode == USE_FC) begin  //全连接层不滑窗，仅需1次trigger，trigger即可将sop_locked清零
            sop_locked <= 1'b0;
        end
        */
        else if(inbuf_sop_o) begin
            sop_locked <= 1'b1;
        end
        else begin
            sop_locked <= sop_locked;
        end
    end

    always @(posedge clk_i) begin
        if(current_program_trigger && inbuf_mode == USE_FC) begin
            sop_locked_update <= 1'b0;
        end
        else begin
            sop_locked_update <= sop_locked;
        end
    end

    // Broad Data Logic
    assign word2bit_bitpar_rdy_o = (fsm_cstate == BROAD_DATA) ? inbuf_din_rdy_i : 1'b0;

    // Broad Hsyn Logic
    assign inbuf_hsync_o = (fsm_cstate == BROAD_HSYNC) ? current_program_trigger : 1'b0;

    // Broad Cmd Logic
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            inbuf_cmd_vld_o <= 1'b0;
        end
        else if(inbuf_cmd_fire) begin
            inbuf_cmd_vld_o <= 1'b0;
        end
        else if(fsm_cstate == BROAD_CMD) begin
            inbuf_cmd_vld_o <= 1'b1;
        end
        else begin
            inbuf_cmd_vld_o <= inbuf_cmd_vld_o;
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            program_id_rdy_o <= 1'b1;
        end
        else if(program_id_fire && fsm_cstate == IDLE) begin
            program_id_rdy_o <= 1'b0;
        end
        else if(fsm_cstate == IDLE) begin
            program_id_rdy_o <= 1'b1;
        end
        else begin
            program_id_rdy_o <= program_id_rdy_o;
        end
    end

    //  | program_counter | program_counter_init |progress_counter | pic_size | mode | padding |
    assign program_table_we = update_value_vld_d1 || program_cfg_vld_i;
    assign program_table_index = program_cfg_vld_i ? program_cfg_id_i : current_program;
    assign program_table_entry_update = program_cfg_vld_i ? {sop_locked, program_cfg_counter_value_i, program_cfg_counter_value_i, program_cfg_progress_value_i, program_cfg_progress_value_i, program_cfg_picsize_i, program_cfg_mode_i, program_cfg_padding_i} : {sop_locked_update, program_value_update, program_value_init, progress_value_update, progress_value_init, inbuf_pic_size, inbuf_mode, inbuf_padding};


    table_symbol #(
        .WIDTH(PROGRAM_TABLE_WIDTH),
        .DEPTH(PROGRAM_TABLE_ENTRY)
    ) U_program_table_0 (
        .clk(clk_i),
        .we(program_table_we),
        .addr(program_table_index),
        .din(program_table_entry_update),
        .dout(program_table_entry)
    );

    
endmodule