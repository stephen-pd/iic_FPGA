// +FHEADER ==================================================
// FilePath       : \sr\tb_top.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-24 15:00:42
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-08-24 17:09:53
// Description    : testbench for top.v
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================

`timescale 1ns/1ps
module tb_top #(
    parameters P_START_ADDR = 8'd0;
    parameters AW = 8;
    parameters DW = 128;
    parameters P_DATA_HOLD = 9;//the peior of clk addr is hold
    parameters P_PIC_SIZE = 16*16;//picture size
    parameters CLK_100M = 10;
);

    reg CLK;
    reg RST;
    reg [3:0]fsm_sram_cstate;
    reg [3:0]fsm_sram_nstate;

    reg [7:0]cnt_data_hold;//count time of data hold
    reg [7:0]cnt_vld;//count number of valid

    reg [2:0]cnt_wsram_data_bit;//count the bit of data
    reg [7:0]r_wsram_data;
    wire [DW-1 :0]wsram_data ;//write data

    reg wsram_sop;//start write data to sram

    wire s_cnt_data_hold_eq_pa;
    wire s_cnt_vld_eq_pa;
    wire s_cnt_wsram_data_bit_eq_7;

    localparam FSM_IDLE  = 4'b0001;
    localparam FSM_WDATA = 4'b0010;
    localparam FSM_WDATA_VLD = 4'b0100;
    localparam FSM_STOP = 4'b1000;

    initial begin
        CLK = 0;
        RST = 0;

        wsram_sop = 0;
        #20 RST = ~RST;
        #100 ;

        @(posedge CLK)wsram_sop = 1;
        wsram_sop = 0;

    end
    always #(CLK_100M/2) CLK = ~CLK;

  

/////data hold time////////////////////////
    always @(posedge CLK) begin
        if (!RST) begin
            cnt_data_hold <= 'b0;
        end else begin
            if (s_cnt_data_hold_eq_pa) cnt_data_hold <= 'b0;
            else if (fsm_sram_cstate == FSM_WDATA) cnt_data_hold <= cnt_data_hold + 1'b1;
        end
    end
    assign s_cnt_data_hold_eq_pa = (cnt_data_hold == P_data_HOLD - 1);

/////data vaild count///////////////////////////
    always @(posedge CLK) begin
        if (!RST) begin
            cnt_vld <= 'b0;
        end else begin
            if (s_cnt_vld_eq_pa) cnt_vld <= 'b0;
            else if (fsm_sram_cstate == FSM_WDATA_VLD) cnt_vld <= cnt_vld + 1'b1;
        end
    end
    assign s_cnt_vld_eq_pa = (fsm_sram_cstate == FSM_WDATA_VLD) & (cnt_vld == P_PIC_SIZE - 1);

////data ,data_valid signal generated/////////
    always @(posedge CLK) begin
        if (!RST) begin
            fsm_sram_cstate <= FSM_IDLE ;
        end else begin
            fsm_sram_cstate <= fsm_sram_nstate ;
        end
    end

    always @(*) begin
        case (fsm_sram_nstate)
            FSM_IDLE : begin
                if (wsram_sop) fsm_sram_nstate = FSM_WDATA;
                else fsm_sram_nstate = FSM_IDLE;
            end 

            FSM_WDATA : begin
                if (s_cnt_data_hold_eq_pa) fsm_sram_nstate = FSM_WDATA_VLD ;
                else fsm_sram_nstate = FSM_WDATA;
            end

            FSM_WDATA_VLD : begin
                if (s_cnt_vld_eq_pa) fsm_sram_nstate = FSM_STOP ; 
                else fsm_sram_nstate = FSM_IDLE ;   
            end

            FSM_STOP : begin
                fsm_sram_nstate = FSM_IDLE ;
            end

            default: fsm_sram_nstate = FSM_IDLE ;
        endcase
    end

    always @(posedge CLK)begin//count data bit
        if (!RST) begin
            cnt_wsram_data_bit <= 'b0;
        end else begin
            if (fsm_sram_cstate == FSM_WDATA_VLD) cnt_wsram_data_bit <= cnt_wsram_data_bit + 1;
        end
    end
    assign s_cnt_wsram_data_bit_eq_7 = (cnt_wsram_data_bit == 7) & (fsm_sram_cstate == FSM_WDATA_VLD);

    always @(posedge CLK) begin//wdata to sram , data from 0-255
        if (!RST) begin
            r_wsram_data <= 'b0;
        end else begin
            if (s_cnt_wsram_data_bit_eq_7) r_wsram_data <= r_wsram_data + 1;
        end
    end
    assign wsram_data = { 128{r_wsram_data[cnt_wsram_data_bit]} };
endmodule