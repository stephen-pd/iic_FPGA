module mux_8_1 #(
    parameter DW = 128
) (
    input   [DW*9-1 : 0]REG_ARRAY_BIT0    ,
    input   [DW*9-1 : 0]REG_ARRAY_BIT1    ,
    input   [DW*9-1 : 0]REG_ARRAY_BIT2    ,
    input   [DW*9-1 : 0]REG_ARRAY_BIT3    ,
    input   [DW*9-1 : 0]REG_ARRAY_BIT4    ,
    input   [DW*9-1 : 0]REG_ARRAY_BIT5    ,
    input   [DW*9-1 : 0]REG_ARRAY_BIT6    ,
    input   [DW*9-1 : 0]REG_ARRAY_BIT7    ,

    input   [2    : 0]  CTRL_MUX_8_1      ,

    output  reg [DW*9-1 : 0]REG_ARRAY_1152
);
    always @(*) begin
        case (CTRL_MUX_8_1) 

        3'd0 : REG_ARRAY_1152 = REG_ARRAY_BIT0  ;
        3'd1 : REG_ARRAY_1152 = REG_ARRAY_BIT1  ;
        3'd2 : REG_ARRAY_1152 = REG_ARRAY_BIT2  ;
        3'd3 : REG_ARRAY_1152 = REG_ARRAY_BIT3  ;
        3'd4 : REG_ARRAY_1152 = REG_ARRAY_BIT4  ;
        3'd5 : REG_ARRAY_1152 = REG_ARRAY_BIT5  ;
        3'd6 : REG_ARRAY_1152 = REG_ARRAY_BIT6  ;
        3'd7 : REG_ARRAY_1152 = REG_ARRAY_BIT7  ;

        default : REG_ARRAY_1152 = REG_ARRAY_BIT0  ;       
        endcase
    end
endmodule