module inputbuffer_sram_ctrl#(
    parameter dw=128,
    parameter aw=10
)(
    input   SYS_CLK,
    input   SYS_NRST,

    input   sram_cmd_write_valid,//wvld*wready
    input   [dw-1 :0]sram_cmd_write_data,
    input   [aw-1 :0]sram_cmd_write_addr,

    input   sram_cmd_read_valid,//rvld
    input   [aw+1 :0]sram_cmd_read_addr,//which bank decided by sram status

    output  reg[dw-1 :0]sram_rsp_read_data,
    output  reg sram_rsp_read_valid,

    input   sram_cmd_status_update,//sram2reg_rdy&vld
    input   sram_cmd_start,//data_sop
    input   sram_cmd_end,//read done all 
    output   [3:0]sram_cmd_status,

    //sram interface
    output  reg[2:0]cen,
    output  reg[2:0]wen,
    output  reg[dw-1 :0]din0,
    output  reg[dw-1 :0]din1,
    output  reg[dw-1 :0]din2,
    output  reg[aw-1 :0]a0,
    output  reg[aw-1 :0]a1,
    output  reg[aw-1 :0]a2,

    input   [dw-1 :0]dout0,
    input   [dw-1 :0]dout1,
    input   [dw-1 :0]dout2
);

reg [1:0]r_bank_sel;

reg [3:0] fsm_sram_cstate;
reg [3:0] fsm_sram_nstate;

assign sram_cmd_status = fsm_sram_cstate;

always @(posedge SYS_CLK or negedge SYS_NRST) begin
    if (!SYS_NRST) begin
        r_bank_sel <= 'b0 ;
        sram_rsp_read_valid <= 'b0;
    end 
    else begin
        r_bank_sel <= sram_cmd_read_addr[aw+1 -:2]  ;
        sram_rsp_read_valid <= sram_cmd_read_valid   ;
    end
end

always @(*) begin
    case (r_bank_sel)

        2'b00 : sram_rsp_read_data = dout0;
        2'b01 : sram_rsp_read_data = dout1;
        2'b10 : sram_rsp_read_data = dout2;
        default: sram_rsp_read_data = dout0;

    endcase
end



localparam IDLE              = 4'b0001   ;
localparam WBANK0_RBANK12    = 4'b0010   ;
localparam WBANK1_RBANK02    = 4'b0100   ;
localparam WBANK2_RBANK01    = 4'b1000   ;

always @(posedge SYS_CLK or negedge SYS_NRST) begin
    if (!SYS_NRST) begin
        fsm_sram_cstate <= IDLE ;
    end else begin
        fsm_sram_cstate <= fsm_sram_nstate  ;
    end
end

always @(*) begin
    case (fsm_sram_cstate)
        
        IDLE :begin
            if (sram_cmd_start)begin
                fsm_sram_nstate = WBANK0_RBANK12;
            end 
            else begin
                fsm_sram_nstate = IDLE;
            end
        end

        WBANK0_RBANK12 :begin
            if (sram_cmd_end)begin
                fsm_sram_nstate = IDLE;
            end 
            else if (sram_cmd_status_update)begin
                fsm_sram_nstate = WBANK1_RBANK02;
            end 
            else begin
                fsm_sram_nstate = WBANK0_RBANK12;
            end
        end
        
        WBANK1_RBANK02 :begin
            if (sram_cmd_end)begin
                fsm_sram_nstate = IDLE;
            end 
            else if (sram_cmd_status_update)begin
                fsm_sram_nstate = WBANK2_RBANK01;
            end 
            else begin
                fsm_sram_nstate = WBANK1_RBANK02;
            end
        end

        WBANK2_RBANK01 :begin
            if (sram_cmd_end)begin
                fsm_sram_nstate = IDLE;
            end 
            else if (sram_cmd_status_update)begin
                fsm_sram_nstate = WBANK0_RBANK12;
            end 
            else begin
                fsm_sram_nstate = WBANK2_RBANK01;
            end
        end

        default : fsm_sram_nstate = IDLE;

    endcase
end

always @(*) begin
    if (fsm_sram_cstate == WBANK0_RBANK12)begin
        cen = {sram_cmd_read_valid  ,sram_cmd_read_valid  ,sram_cmd_write_valid};
        wen = 3'b001;

        a0  = sram_cmd_write_addr;
        a1  = sram_cmd_read_addr[aw-1 :0];
        a2  = sram_cmd_read_addr[aw-1 :0];

        din0= sram_cmd_write_data;
        din1= 'b0;
        din2= 'b0; 
    end
    else if(fsm_sram_cstate == WBANK1_RBANK02)begin
        cen = {sram_cmd_read_valid  ,sram_cmd_write_valid ,sram_cmd_read_valid};
        wen = 3'b010;

        a0  = sram_cmd_read_addr[aw-1 :0];
        a1  = sram_cmd_write_addr;
        a2  = sram_cmd_read_addr[aw-1 :0];

        din0= 'b0;
        din1= sram_cmd_write_data;
        din2= 'b0;
    end
    else if(fsm_sram_cstate == WBANK2_RBANK01)begin
        cen = {sram_cmd_write_valid ,sram_cmd_read_valid   ,sram_cmd_read_valid};
        wen = 3'b100;

        a0  = sram_cmd_read_addr[aw-1 :0];
        a1  = sram_cmd_read_addr[aw-1 :0];
        a2  = sram_cmd_write_addr;

        din0= 'b0;
        din1= 'b0;
        din2= sram_cmd_write_data;
    end
    else begin
        cen = 'b0;
        wen = 'b0;

        a0  = 'b0;
        a1  = 'b0;
        a2  = 'b0;

        din0= 'b0;
        din1= 'b0;
        din2= 'b0;
    end

end



endmodule