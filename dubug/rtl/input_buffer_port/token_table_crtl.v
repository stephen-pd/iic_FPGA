// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\input_buffer_port\token_table_crtl.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-09-06 16:30:17
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-09-25 14:38:51
// Description    : Token Table Entry
//                  | value | init_value | dst_program |
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module token_table_ctrl #(
    parameter MAX_COUNTER_VALUE = 32,
    parameter TOKEN_TABLE_ENTRY = 32,
    parameter PROGRAM_TABLE_ENTRY = 32
)(
    input   wire                                        clk_i,
    input   wire                                        rst_n_i,

    input   wire    [$clog2(TOKEN_TABLE_ENTRY)-1:0]     token_id_payload_i,
    input   wire                                        token_id_vld_i,
    output  reg                                         token_id_rdy_o,
    
    output  wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     token_value_o,
    // token table config port
    input   wire    [$clog2(TOKEN_TABLE_ENTRY)-1:0]     token_cfg_id_i,
    input   wire    [$clog2(MAX_COUNTER_VALUE)-1:0]     token_cfg_counter_value_i,
    input   wire    [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   token_cfg_dst_program_i,
    input   wire                                        token_cfg_vld_i,

    input   wire                                        program_id_rdy_i,
    output  reg                                         program_id_vld_o,            // 指示本次访问有效
    output  wire    [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   program_id_payload_o,       // 本次访问的index
    output  reg                                         program_id_triggerd_o      // 本次访问是否触发program计数器加一，即hsync
);

    localparam TOKEN_TABLE_WIDTH = $clog2(MAX_COUNTER_VALUE) + $clog2(PROGRAM_TABLE_ENTRY) + $clog2(MAX_COUNTER_VALUE);
    `define DST_PROGRAM_RANGE   $clog2(PROGRAM_TABLE_ENTRY)-1:0
    `define TOKEN_VALUE_RANGE   TOKEN_TABLE_WIDTH-1:$clog2(MAX_COUNTER_VALUE) + $clog2(PROGRAM_TABLE_ENTRY)
    `define TOKEN_INIT_VALUE_RANGE  $clog2(MAX_COUNTER_VALUE) + $clog2(PROGRAM_TABLE_ENTRY)-1:$clog2(PROGRAM_TABLE_ENTRY)


    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     token_value_table       [TOKEN_TABLE_ENTRY-1:0];
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     token_value_init_table  [TOKEN_TABLE_ENTRY-1:0];
    reg     [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   dst_program_table       [TOKEN_TABLE_ENTRY-1:0];
    
    wire    [$clog2(TOKEN_TABLE_ENTRY)-1:0]     token_table_index;
    wire                                        token_table_we;
    wire    [TOKEN_TABLE_WIDTH-1:0]             token_table_entry;          //当前token表项
    wire    [TOKEN_TABLE_WIDTH-1:0]             token_table_entry_update;   //更新token表项

    wire                                        program_triggered;

    reg     [$clog2(TOKEN_TABLE_ENTRY)-1:0]     current_token;

    reg                                         token_locked;
    reg                                         rd_entry_vld;
    reg                                         update_value_vld;

    reg                                         cmd_hold;

    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     token_value;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     token_value_update;
    reg     [$clog2(MAX_COUNTER_VALUE)-1:0]     token_init_value;
    reg     [$clog2(PROGRAM_TABLE_ENTRY)-1:0]   dst_program;

    

    localparam IDLE = 3'h0;
    localparam FETCH = 3'h1;
    localparam UPDATE = 3'h2;

    reg     [2:0]       fsm_cstate;
    reg     [2:0]       fsm_nstate;

    wire                token_id_fire;
    wire                program_id_fire;

    assign token_id_fire = token_id_rdy_o && token_id_vld_i;
    assign program_id_fire = program_id_vld_o && program_id_rdy_i;

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
                if(token_id_fire) begin
                    fsm_nstate = FETCH;
                end
            end
            FETCH : begin
                if(rd_entry_vld) begin
                    fsm_nstate = UPDATE;
                end
            end
            UPDATE : begin
                if(program_id_fire) begin
                    fsm_nstate = IDLE;
                end
            end
            default : fsm_nstate = IDLE;
        endcase
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            token_id_rdy_o <= 1'b1;
        end
        else if(token_id_vld_i && fsm_cstate == IDLE) begin
            token_id_rdy_o <= 1'b0;
        end
        else if(fsm_cstate == IDLE) begin
            token_id_rdy_o <= 1'b1;
        end
        else begin
            token_id_rdy_o <= token_id_rdy_o;
        end
    end

    // token id will be locked until next token arrival
    always @(posedge clk_i) begin
        if(token_id_fire) begin
            current_token <= token_id_payload_i;
            token_locked <= 1'b1;
        end
        else begin
            current_token <= current_token;
            token_locked <= 1'b0;
        end
    end
    always @(posedge clk_i) begin
        rd_entry_vld <= token_locked;
    end


    // access program table, stored in local register
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            token_value <= 'h0;
            token_init_value <= 'h0;
            dst_program <= 'h0;
        end
        else if(fsm_cstate == FETCH) begin
            token_value <= token_table_entry[`TOKEN_VALUE_RANGE];
            token_init_value <= token_table_entry[`TOKEN_INIT_VALUE_RANGE];
            dst_program <= token_table_entry[`DST_PROGRAM_RANGE];
            
        end
        else begin
            token_value <= token_value;
            token_init_value <= token_init_value;
            dst_program <= dst_program;
        end
    end

    assign token_value_o = token_value;
    assign program_id_payload_o = dst_program;

    // update 
    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            update_value_vld <= 1'b0;
        end
        else if(program_id_fire) begin
            update_value_vld <= 1'b0;
        end
        else if(fsm_cstate == UPDATE) begin
            update_value_vld <= 1'b1;
        end
        else begin
            update_value_vld <= update_value_vld;
        end
    end

    // token table update
    always @(posedge clk_i) begin
        if(fsm_cstate == UPDATE && !update_value_vld) begin
            if(token_value == 'h0) begin
                token_value_update <= token_init_value;
            end
            else begin
                token_value_update <= token_value + 1'b1;
            end
        end
        else begin
            token_value_update <= token_value_update;
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            program_id_triggerd_o <= 1'b0;
        end
        else if(program_id_fire) begin
            program_id_triggerd_o <=1'b0;
        end
        else if(fsm_cstate == UPDATE && token_value == 'h0) begin
            program_id_triggerd_o <= 1'b1;
        end
        else begin
            program_id_triggerd_o <= program_id_triggerd_o;
        end
    end

    always @(posedge clk_i or negedge rst_n_i) begin
        if(!rst_n_i) begin
            program_id_vld_o <= 1'b0;
        end
        else if(program_id_fire) begin
            program_id_vld_o <= 1'b0;
        end
        else if(update_value_vld) begin
            program_id_vld_o <= 1'b1;
        end
        else begin
            program_id_vld_o <= program_id_vld_o;
        end
    end

    assign token_table_we = update_value_vld || token_cfg_vld_i;
    assign token_table_index = token_cfg_vld_i ? token_cfg_id_i : current_token;
    assign token_table_entry_update = token_cfg_vld_i ? {token_cfg_counter_value_i, token_cfg_counter_value_i, token_cfg_dst_program_i} : {token_value_update, token_init_value, dst_program};


    table_symbol #(
        .WIDTH(TOKEN_TABLE_WIDTH),
        .DEPTH(TOKEN_TABLE_ENTRY)
    ) U_token_table_0 (
        .clk(clk_i),
        .we(token_table_we),
        .addr(token_table_index),
        .din(token_table_entry_update),
        .dout(token_table_entry)
    );

endmodule