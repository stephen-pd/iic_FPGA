// +FHEADER ==================================================
// FilePath       : \MPW2022_11\rtl\utils\apb_timer.v
// Author         : Ziheng Zhou ziheng.zhou.1999@qq.com
// CreateDate     : 2022-08-27 20:02:31
// LastEditors    : Ziheng Zhou ziheng.zhou.1999@qq.com
// LastEditTime   : 2022-08-27 21:24:00
// Description    : Memory mapped timera & timerb
//                  All transefer has no wait states
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module apb_timer(
    input   wire                    clk_i,
    input   wire                    rst_i,

    input   wire    [4:0]           apb_paddr_s,
    input   wire                    apb_pwrite_s,
    input   wire                    apb_psel_s,
    input   wire                    apb_penable_s,
    input   wire    [31:0]          apb_pwdata_s,
    output  reg     [31:0]          apb_prdata_s,
    output  reg                     apb_pready_s
);

    localparam  TIMERA_VAL = 5'h00;     //R
    localparam  TIMERA_CMP = 5'h04;     //W
    localparam  TIMERA_CFG = 5'h08;     //W
    localparam  TIMERA_TIC = 5'h0c;     //R

    localparam  TIMERB_VAL = 5'h10;     //R
    localparam  TIMERB_CMP = 5'h14;     //W
    localparam  TIMERB_CFG = 5'h18;     //W
    localparam  TIMERB_TIC = 5'h1c;     //R

    reg             timer_a_clr;
    reg             timer_a_ena;
    reg     [31:0]  timer_a_cmp;
    wire    [31:0]  timer_a_val;
    wire            timer_a_tick;

    reg             timer_b_clr;
    reg             timer_b_ena;
    reg     [31:0]  timer_b_cmp;
    wire    [31:0]  timer_b_val;
    wire            timer_b_tick;


    //===========================================
    // description: timera config register write logic, clr = timera_cfg[1], ena = timera_cfg[0]
        
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            timer_a_clr <= 1'b1;
            timer_a_ena <= 1'b0;
        end
        else if(apb_psel_s && apb_pwrite_s && apb_paddr_s == TIMERA_CFG) begin
            timer_a_clr <= apb_pwdata_s[1];
            timer_a_ena <= apb_pwdata_s[0];
        end
    end

    //===========================================
    // description: timera cmp_value register write logic
        
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            timer_a_cmp <= 32'hffff_ffff;
        end
        else if(apb_psel_s && apb_pwrite_s && apb_paddr_s == TIMERA_CMP) begin
            timer_a_cmp <= apb_pwdata_s;
        end
    end

    //===========================================
    // description: timerb config register write logic
        
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            timer_b_clr <= 1'b1;
            timer_b_ena <= 1'b0;
        end
        else if(apb_psel_s && apb_pwrite_s && apb_paddr_s == TIMERB_CFG) begin
            timer_b_clr <= apb_pwdata_s[1];
            timer_b_ena <= apb_pwdata_s[0];
        end
    end

    //===========================================
    // description: timerb cmp value register write logic
    
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            timer_b_cmp <= 32'hffff_ffff;
        end
        else if(apb_psel_s && apb_pwrite_s && apb_paddr_s == TIMERB_CMP) begin
            timer_b_cmp <= apb_pwdata_s;
        end
    end

    //===========================================
    // description: timera & timerb, value & tick read logic 
        
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            apb_prdata_s <= 32'h0;
        end
        else if(apb_psel_s) begin
            case(apb_paddr_s) 
                TIMERA_VAL : apb_prdata_s <= timer_a_val;
                TIMERA_TIC : apb_prdata_s <= timer_a_tick;
                TIMERB_VAL : apb_prdata_s <= timer_b_val;
                TIMERB_TIC : apb_prdata_s <= timer_b_tick;
            endcase
        end
    end

    //===========================================
    // description: apb_pready logic, transfer has no wait
        
    always @(posedge clk_i or posedge rst_i) begin
        if(rst_i) begin
            apb_pready_s <= 1'b0;
        end
        else if(apb_penable_s)begin
            apb_pready_s <= 1'b0;
        end
        else if(apb_psel_s) begin
            apb_pready_s <= 1'b1;
        end
    end

    timer U_timer_A(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .clr_i(timer_a_clr),
        .ena_i(timer_a_ena),
        .cmp_value_i(timer_a_cmp),
        .value_o(timer_a_val),
        .tick_o(timer_a_tick)
    );

    timer U_timer_B(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .clr_i(timer_b_clr),
        .ena_i(timer_b_ena),
        .cmp_value_i(timer_b_cmp),
        .value_o(timer_b_val),
        .tick_o(timer_b_tick)
    );
    

endmodule