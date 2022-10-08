module mux_6_1 #(
    parameter DW = 128
)(
    input   [2:0]mux_6_1_ctrl,

    input   [DW*9-1 :0]mux_6_1_in,

    output  reg[DW-1 :0]mux_6_1_out_0,
    output  reg[DW-1 :0]mux_6_1_out_1,
    output  reg[DW-1 :0]mux_6_1_out_2,
    output  reg[DW-1 :0]mux_6_1_out_3,
    output  reg[DW-1 :0]mux_6_1_out_4,
    output  reg[DW-1 :0]mux_6_1_out_5,
    output  reg[DW-1 :0]mux_6_1_out_6,
    output  reg[DW-1 :0]mux_6_1_out_7,
    output  reg[DW-1 :0]mux_6_1_out_8
);

wire        [DW-1 :  0]   REG2MUX_0     ;
wire        [DW-1 :  0]   REG2MUX_1     ;
wire        [DW-1 :  0]   REG2MUX_2     ;
wire        [DW-1 :  0]   REG2MUX_3     ;
wire        [DW-1 :  0]   REG2MUX_4     ;
wire        [DW-1 :  0]   REG2MUX_5     ;
wire        [DW-1 :  0]   REG2MUX_6     ;
wire        [DW-1 :  0]   REG2MUX_7     ;
wire        [DW-1 :  0]   REG2MUX_8     ;

assign  REG2MUX_0 = mux_6_1_in[DW*9-1 -:DW] ;
assign  REG2MUX_1 = mux_6_1_in[DW*8-1 -:DW] ;
assign  REG2MUX_2 = mux_6_1_in[DW*7-1 -:DW] ;
assign  REG2MUX_3 = mux_6_1_in[DW*6-1 -:DW] ;
assign  REG2MUX_4 = mux_6_1_in[DW*5-1 -:DW] ;
assign  REG2MUX_5 = mux_6_1_in[DW*4-1 -:DW] ;
assign  REG2MUX_6 = mux_6_1_in[DW*3-1 -:DW] ;
assign  REG2MUX_7 = mux_6_1_in[DW*2-1 -:DW] ;
assign  REG2MUX_8 = mux_6_1_in[DW*1-1 -:DW] ;

always @(*) begin
    case(mux_6_1_ctrl)
        
        3'b000 : begin
            mux_6_1_out_0 = REG2MUX_0   ;
            mux_6_1_out_1 = REG2MUX_1   ;
            mux_6_1_out_2 = REG2MUX_2   ;
            mux_6_1_out_3 = REG2MUX_3   ;
            mux_6_1_out_4 = REG2MUX_4   ;
            mux_6_1_out_5 = REG2MUX_5   ;
            mux_6_1_out_6 = REG2MUX_6   ;
            mux_6_1_out_7 = REG2MUX_7   ;
            mux_6_1_out_8 = REG2MUX_8   ;
            
        end
        
        3'b001 : begin
            mux_6_1_out_0 = REG2MUX_1   ;
            mux_6_1_out_1 = REG2MUX_2   ;
            mux_6_1_out_2 = REG2MUX_0   ;
            mux_6_1_out_3 = REG2MUX_4   ;
            mux_6_1_out_4 = REG2MUX_5   ;
            mux_6_1_out_5 = REG2MUX_3   ;
            mux_6_1_out_6 = REG2MUX_7   ;
            mux_6_1_out_7 = REG2MUX_8   ;
            mux_6_1_out_8 = REG2MUX_6   ;
        end
        
        3'b010 : begin
            mux_6_1_out_0 = REG2MUX_4   ;
            mux_6_1_out_1 = REG2MUX_5   ;
            mux_6_1_out_2 = REG2MUX_3   ;
            mux_6_1_out_3 = REG2MUX_7   ;
            mux_6_1_out_4 = REG2MUX_8   ;
            mux_6_1_out_5 = REG2MUX_6   ;
            mux_6_1_out_6 = REG2MUX_1   ;
            mux_6_1_out_7 = REG2MUX_2   ;
            mux_6_1_out_8 = REG2MUX_0   ;
        end
        
        3'b011 : begin
            mux_6_1_out_0 = REG2MUX_3   ;
            mux_6_1_out_1 = REG2MUX_4   ;
            mux_6_1_out_2 = REG2MUX_5   ;
            mux_6_1_out_3 = REG2MUX_6   ;
            mux_6_1_out_4 = REG2MUX_7   ;
            mux_6_1_out_5 = REG2MUX_8   ;
            mux_6_1_out_6 = REG2MUX_0   ;
            mux_6_1_out_7 = REG2MUX_1   ;
            mux_6_1_out_8 = REG2MUX_2   ;
        end
        
        3'b100 : begin
            mux_6_1_out_0 = REG2MUX_6   ;
            mux_6_1_out_1 = REG2MUX_7   ;
            mux_6_1_out_2 = REG2MUX_8   ;
            mux_6_1_out_3 = REG2MUX_0   ;
            mux_6_1_out_4 = REG2MUX_1   ;
            mux_6_1_out_5 = REG2MUX_2   ;
            mux_6_1_out_6 = REG2MUX_3   ;
            mux_6_1_out_7 = REG2MUX_4   ;
            mux_6_1_out_8 = REG2MUX_5   ;
        end
        
        3'b101 : begin
            mux_6_1_out_0 = REG2MUX_7   ;
            mux_6_1_out_1 = REG2MUX_8   ;
            mux_6_1_out_2 = REG2MUX_6   ;
            mux_6_1_out_3 = REG2MUX_1   ;
            mux_6_1_out_4 = REG2MUX_2   ;
            mux_6_1_out_5 = REG2MUX_0   ;
            mux_6_1_out_6 = REG2MUX_4   ;
            mux_6_1_out_7 = REG2MUX_5   ;
            mux_6_1_out_8 = REG2MUX_3   ;
        end
        
        default : begin
            mux_6_1_out_0 = REG2MUX_0   ;
            mux_6_1_out_1 = REG2MUX_1   ;
            mux_6_1_out_2 = REG2MUX_2   ;
            mux_6_1_out_3 = REG2MUX_3   ;
            mux_6_1_out_4 = REG2MUX_4   ;
            mux_6_1_out_5 = REG2MUX_5   ;
            mux_6_1_out_6 = REG2MUX_6   ;
            mux_6_1_out_7 = REG2MUX_7   ;
            mux_6_1_out_8 = REG2MUX_8   ;
        end
        
    endcase
end
    
endmodule