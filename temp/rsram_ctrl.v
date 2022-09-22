module rsram_ctrl (
    input genaddr_start,
    input bank_ok,
    input SYS_CLK,
    input SYS_RST,

    input PIC_SIZE,

    output reg rsram_addr[7:0],
    output reg sram2regarry_addr_o[3:0],
    output reg r_bitsel[2:0],
    output wire r_cnt_genaddr_valid
);

reg r_banksel[1:0];//from 00 to 10, 00 select bank1、2; 01 select bank2、3；10 select bank3、1
wire s_banksel_eq_10;
always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        r_banksel <= 'b0;
    end else begin
        if (rsram_start || (s_banksel_eq_10)) begin
            r_banksel <= 'b0;
        end else if (bank_ok) begin
            r_banksel <= r_banksel + 1'b1;
        end
    end
end
assign s_banksel_eq_10 = bank_ok & (r_banksel == 2'b10);

reg r_bitsel[2:0];//from 000 to 111, sel which bit register
wire s_genaddr_sop;//when cnt rece == 9 or 3
wire s_matrix_end;
always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        r_bitsel <= 'b0;
    end else begin
        if (s_genaddr_sop) begin
            r_bitsel <= r_bitsel + 1'b1;
        end
    end
end
assign s_matrix_end = (r_bitsel == 3'b111) & s_genaddr_sop;


reg [6:0]r_FSM_STATE;
localparam P_IDLE_CNN = 7'b0000001;
localparam P_FULL_CNN = 7'b0000010;
localparam P_RIGH_CNN = 7'b0000100;
localparam P_DOW1_CNN = 7'b0001000;
localparam P_LEFT_CNN = 7'b0010000;
localparam P_DOW2_CNN = 7'b0100000;
localparam P_DONE_CNN = 7'b1000000;

always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        r_FSM_STATE <= P_IDLE_CNN;
    end else begin
        case (r_FSM_STATE)
            
        P_IDLE_CNN :
            if(genaddr_start) begin
                r_FSM_STATE <= P_FULL_CNN;
            end

        P_FULL_CNN :
            if(s_matrix_end) begin
                if (mode1) begin
                    r_FSM_STATE <= P_RIGH_CNN;
                end else if (mode2 && mode3) begin
                    r_FSM_STATE <= P_DOW1_CNN;
                end
                
            end

        P_RIGH_CNN :
            if(s_matrix_end & mode1) begin
                r_FSM_STATE <= P_DOW1_CNN;
            end
        
        P_DOW1_CNN :
            if (s_cnn_state_end)begin
                r_FSM_STATE <= P_DONE_CNN;
            end else if (s_line_end)begin
                r_FSM_STATE <= P_IDLE_CNN;
            end else if (s_matrix_end & mode1) begin
                r_FSM_STATE <= P_LEFT_CNN;
            end
        
        P_LEFT_CNN :
            if(s_matrix_end & mode1) begin
                r_FSM_STATE <= P_DOW2_CNN;
            end
        
        P_DOW2_CNN :
            if(s_cnn_state_end)begin
                r_FSM_STATE <= P_DONE_CNN;
            end else if(s_matrix_end & mode1) begin
                r_FSM_STATE <= P_RIGH_CNN;
            end
        
        P_DONE_CNN :
            r_FSM_STATE <= P_IDLE_CNN;

            default: begin
                r_FSM_STATE <= P_IDLE_CNN;
            end
        endcase
    end
end
assign s_IDLE_CNN = r_FSM_STATE[0];
assign s_FULL_CNN = r_FSM_STATE[1];
assign s_RIGH_CNN = r_FSM_STATE[2];
assign s_DOW1_CNN = r_FSM_STATE[3];
assign s_LEFT_CNN = r_FSM_STATE[4];
assign s_DOW2_CNN = r_FSM_STATE[5];
assign s_DONE_CNN = r_FSM_STATE[6];


wire s_line_end;//3 or 4 line pix needed for a cnn line
wire s_cnn_state_end;//for fsm state to r_DONE_CNN

signed  reg [7:0]X;
signed  reg [7:0]Y;//the coordinate of cnn in picture
always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        X <= 'b0;
        Y <= 'b0; 
    end else begin
        if (genaddr_start) begin
            X <= 1 - padding;
            Y <= 1 - padding;
        end else if (s_line_end) begin
            if (mode1 || mode3)begin
                X <= X + 2;
                Y <= 1 - padding;
            end else if (mode2) begin
                X <= X + 1;
                Y <= 1 - padding;
            end
        end 
        else if (s_matrix_end) begin
            if ((s_FULL_CNN & mode1) || s_DOW2_CNN) begin
                X <= X + 1;
                Y <= Y;
            end else if (s_FULL_CNN & (mode2 || mode3)) begin
                X <= X;
                Y <= Y + 1;
            end else if (s_RIGH_CNN || s_LEFT_CNN) begin
                X <= X;
                Y <= Y + 1
            end else if (s_DOW1_CNN) begin
                X <= X - 1;
                Y <= Y;
        end
    end
    end
end

reg [7:0] r_cnt_matrix;//count matrix for line, in mode1/3 0-2N-1 , in mode2 0-N-1 , to DONE_CNN
wire s_cnn_state_end;//the signal for FSM to done

always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        r_cnt_matrix <= 'b0;
    end else begin
        if (genaddr_start || bank_ok) begin
            r_cnt_matrix <= 'b0;
        end else if (s_cnn_state_end) begin
            r_cnt_matrix <= 'b0;
        end else if (s_matrix_end) begin
            r_cnt_matrix <= r_cnt_matrix + 1'b1;
        end
    end
end

assign s_cnn_state_end = s_matrix_end & ( (mode1||mode2) ? (r_cnt_matrix == PIC_SIZE*2 - 1) : (mode3 && (r_cnt_matrix == PIC_SIZE - 1)) );

wire s_line_end;//a cnn line end, in mode 1 when equal 2N , in mode 2/3 when equal N or 2N , to IDLE_CNN 
assign s_LIne_end = s_matrix_end & ( (mode3||mode2) ? ((r_cnt_matrix == PIC_SIZE*2 - 1)||(r_cnt_matrix == PIC_SIZE - 1)) : (mode1 && (r_cnt_matrix == PIC_SIZE - 1)) );

wire s_num_addr[3:0];
assign s_num_addr = s_FULL_CNN ? 4'd9 : 4'd3;


reg r_cnt_genaddr_L[1:0];
reg r_cnt_genaddr_M[1:0];//for 9 or 3 addr generated, define counter from 0、1、2、4、5、6、8、9、10
reg r_cnt_genaddr_valid;
wire s_cnt_genaddr_valid_up;
wire s_cnt_genaddr_valid_down;
wire s_cnt_genaddr_L_eq_10;
wire s_cnt_genaddr_M_eq_10;
always @(posedge SYS_CLK) begin
    if (!SYS_RST)begin
        r_cnt_genaddr_valid <= 'b0;
    end else begin
        if (s_cnt_genaddr_valid_up) begin
            r_cnt_genaddr_valid <= 'b0;
        end else if (s_cnt_genaddr_valid_down) begin
            r_cnt_genaddr_valid <= 1'b1;
        end
    end
end
assign s_cnt_genaddr_valid_up = genaddr_start || bank_ok || s_genaddr_sop;
assign s_cnt_genaddr_valid_down =  (r_cnt_genaddr == s_num_addr);
always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        r_cnt_genaddr <= 'b0;
    end else begin
        if (s_cnt_genaddr_valid)begin
            if (s_cnt_genaddr_M_eq_10) begin
                r_cnt_genaddr_M <= 'b0;
            end else if (s_cnt_genaddr_L_eq_10)[2:0] reg_stack [7:0];//define 9x3 register stack, each 3 bit 

                r_cnt_genaddr_M <= r_cnt_genaddr_M + 1'b1;
                r_cnt_genaddr_L <= 'b0;
            end else begin
                r_cnt_genaddr_L <= r_cnt_genaddr_L + 1'b1;
            end
        end
    end 
assign s_cnt_genaddr_L_eq_10 = r_cnt_genaddr_L == 2'b10;
assign s_cnt_genaddr_M_eq_10 = (r_cnt_genaddr_M == 2'b10) & s_cnt_genaddr_L_eq_10;
assign s_cnt_genaddr_valid_down = (r_cnt_genaddr == s_num_addr - 1);


reg rsram_addr[10:0];
always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        rsram_addr <= 'b0;
    end else begin
        if (s_cnt_genaddr_valid & s_FULL_CNN) begin//when generate 9 addr
            rsram_addr[10:9] <= r_banksel; 
            rsram_addr[8]    <= (X-1 + r_cnt_genaddr_L) + padding;
            rsram_addr[7:0]  <= (Y-1 + r_cnt_genaddr_M)*8 + r_bitsel;
        end else if (s_cnt_genaddr_valid & (!s_IDLE_CNN) & (!s_FULL_CNN)) begin//when generate 3 addr
            if (s_RIGH_CNN) begin
                rsram_addr[10:9] <= r_banksel; 
                rsram_addr[8]    <= X+1 + padding;
                rsram_addr[7:0]  <= (Y-1 + r_cnt_genaddr_M)*8 + r_bitsel;
            end else if (s_DOW1_CNN || s_DOW2_CNN) begin
                rsram_addr[10:9] <= r_banksel; 
                rsram_addr[8]    <= (X-1 + r_cnt_genaddr_L) + padding;
                rsram_addr[7:0]  <= (Y+1)*8 + r_bitsel;
            end else if (P_LEFT_CNN) begin
                rsram_addr[10:9] <= r_banksel; 
                rsram_addr[8]    <= (X-1 ) + padding;
                rsram_addr[7:0]  <= (Y-1 + r_cnt_genaddr_M)*8 + r_bitsel;
            end
        end
    end
end

reg [2:0] reg_stack [11:0];//define 9x3 register stack, each 3 bit 
always @(posedge SYS_CLK) begin
    if (!SYS_RST)begin
        reg_stack[0] <= 'b0;
        reg_stack[1] <= 'b0;
        reg_stack[2] <= 'b0;
    end else begin
        if (s_IDLE_CNN) begin
            reg_stack[0] <= 12'b0000_0001_0010;
            reg_stack[1] <= 12'b0011_0100_0101;
            reg_stack[2] <= 12'b0110_0111_1000;
        end else if (s_FULL_CNN & s_matrix_end & mode1)begin
            reg_stack[0] <= {reg_stack[0][3:0] , reg_stack[0][7:4] , reg_stack[0][11:8]};
            reg_stack[1] <= {reg_stack[1][3:0] , reg_stack[1][7:4] , reg_stack[1][11:8]};
            reg_stack[2] <= {reg_stack[2][3:0] , reg_stack[2][7:4] , reg_stack[2][11:8]};
        end else if (s_FULL_CNN & s_matrix_end & (mode2 || mode3))begin
            reg_stack[0] <= reg_stack[1];
            reg_stack[1] <= reg_stack[2];
            reg_stack[2] <= reg_stack[0];
        end else if (s_RIGH_CNN & s_matrix_end & mode1)begin
            reg_stack[0] <= reg_stack[1];
            reg_stack[1] <= reg_stack[2];
            reg_stack[2] <= reg_stack[0];
        end else if (s_DOW1_CNN & s_matrix_end & mode1)begin
            reg_stack[0] <= {reg_stack[0][7:4] , reg_stack[0][3:0] , reg_stack[0][11:8]};
            reg_stack[1] <= {reg_stack[1][7:4] , reg_stack[1][3:0] , reg_stack[1][11:8]};
            reg_stack[2] <= {reg_stack[2][7:4] , reg_stack[2][3:0] , reg_stack[2][11:8]};
        end else if (s_LEFT_CNN & s_matrix_end & mode1)begin
            reg_stack[0] <= reg_stack[1];
            reg_stack[1] <= reg_stack[2];
            reg_stack[2] <= reg_stack[0];
        end else if (s_DOW2_CNN & s_matrix_end & mdoe1)begin
            reg_stack[0] <= {reg_stack[0][3:0] , reg_stack[0][7:4] , reg_stack[0][11:8]};
            reg_stack[1] <= {reg_stack[1][3:0] , reg_stack[1][7:4] , reg_stack[1][11:8]};
            reg_stack[2] <= {reg_stack[2][3:0] , reg_stack[2][7:4] , reg_stack[2][11:8]};
        end else if (s_DOW1_CNN & s_matrix_end & (mdoe2 || mode3))begin
            reg_stack[0] <= reg_stack[1];
            reg_stack[1] <= reg_stack[2];
            reg_stack[2] <= reg_stack[0];
        end
    end
end

reg [3:0]sram2regarry_addr_o;
always @(posedge SYS_CLK) begin
    if (!SYS_RST) begin
        sram2regarry_addr_o <= 'b0;
    end else begin
        if (r_cnt_genaddr_valid) begin
            if (s_FULL_CNN) begin
                sram2regarry_addr_o <= sram2regarry_addr_o + 1'b1;
            end else if (s_RIGH_CNN) begin
                sram2regarry_addr_o <= reg_stack[r_cnt_genaddr_L][3:0];
            end else if (s_DOW1_CNN || s_DOW2_CNN) begin
                sram2regarry_addr_o <= reg_stack[2][4*r_cnt_genaddr_L +: 4];
            end else if (s_LEFT_CNN) begin
                sram2regarry_addr_o <= reg_stack[r_cnt_genaddr_L][11:8];
            end
        end
    end
end




endmodule