// +FHEADER ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
// FilePath       : \sr\mux.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-24 17:24:09
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-08-24 22:16:18
// Description    : between opu and reg_array
//
//
//
//
// Rev 1.0
//
//
// -FHEADER ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
module mux_6_1 #(parameter DW = 128)
               (input [2 :0] CTRL_MUX_6_1,
                 input [DW*9-1 :0] REG_ARRAY_1152,
                 output reg [DW-1 : 0] MUX2OPU_0,
                 output reg [DW-1 : 0] MUX2OPU_1,
                 output reg [DW-1 : 0] MUX2OPU_2,
                 output reg [DW-1 : 0] MUX2OPU_3,
                 output reg [DW-1 : 0] MUX2OPU_4,
                 output reg [DW-1 : 0] MUX2OPU_5,
                 output reg [DW-1 : 0] MUX2OPU_6,
                 output reg [DW-1 : 0] MUX2OPU_7,
                 output reg [DW-1 : 0] MUX2OPU_8);
    wire        [DW-1 :  0]   REG2MUX_0     ;
    wire        [DW-1 :  0]   REG2MUX_1     ;
    wire        [DW-1 :  0]   REG2MUX_2     ;
    wire        [DW-1 :  0]   REG2MUX_3     ;
    wire        [DW-1 :  0]   REG2MUX_4     ;
    wire        [DW-1 :  0]   REG2MUX_5     ;
    wire        [DW-1 :  0]   REG2MUX_6     ;
    wire        [DW-1 :  0]   REG2MUX_7     ;
    wire        [DW-1 :  0]   REG2MUX_8     ;
    
    assign  REG2MUX_0 = REG_ARRAY_1152[DW*9-1 -:DW] ;
    assign  REG2MUX_1 = REG_ARRAY_1152[DW*8-1 -:DW] ;
    assign  REG2MUX_2 = REG_ARRAY_1152[DW*7-1 -:DW] ;
    assign  REG2MUX_3 = REG_ARRAY_1152[DW*6-1 -:DW] ;
    assign  REG2MUX_4 = REG_ARRAY_1152[DW*5-1 -:DW] ;
    assign  REG2MUX_5 = REG_ARRAY_1152[DW*4-1 -:DW] ;
    assign  REG2MUX_6 = REG_ARRAY_1152[DW*3-1 -:DW] ;
    assign  REG2MUX_7 = REG_ARRAY_1152[DW*2-1 -:DW] ;
    assign  REG2MUX_8 = REG_ARRAY_1152[DW*1-1 -:DW] ;
    
    always @(*) begin
        case(CTRL_MUX_6_1)
            
            3'b000 : begin
                MUX2OPU_0 = REG2MUX_0   ;
                MUX2OPU_1 = REG2MUX_1   ;
                MUX2OPU_2 = REG2MUX_2   ;
                MUX2OPU_3 = REG2MUX_3   ;
                MUX2OPU_4 = REG2MUX_4   ;
                MUX2OPU_5 = REG2MUX_5   ;
                MUX2OPU_6 = REG2MUX_6   ;
                MUX2OPU_7 = REG2MUX_7   ;
                MUX2OPU_8 = REG2MUX_8   ;
                
            end
            
            3'b001 : begin
                MUX2OPU_0 = REG2MUX_1   ;
                MUX2OPU_1 = REG2MUX_2   ;
                MUX2OPU_2 = REG2MUX_0   ;
                MUX2OPU_3 = REG2MUX_4   ;
                MUX2OPU_4 = REG2MUX_5   ;
                MUX2OPU_5 = REG2MUX_3   ;
                MUX2OPU_6 = REG2MUX_7   ;
                MUX2OPU_7 = REG2MUX_8   ;
                MUX2OPU_8 = REG2MUX_6   ;
            end
            
            3'b010 : begin
                MUX2OPU_0 = REG2MUX_4   ;
                MUX2OPU_1 = REG2MUX_5   ;
                MUX2OPU_2 = REG2MUX_3   ;
                MUX2OPU_3 = REG2MUX_7   ;
                MUX2OPU_4 = REG2MUX_8   ;
                MUX2OPU_5 = REG2MUX_6   ;
                MUX2OPU_6 = REG2MUX_1   ;
                MUX2OPU_7 = REG2MUX_2   ;
                MUX2OPU_8 = REG2MUX_0   ;
            end
            
            3'b011 : begin
                MUX2OPU_0 = REG2MUX_3   ;
                MUX2OPU_1 = REG2MUX_4   ;
                MUX2OPU_2 = REG2MUX_5   ;
                MUX2OPU_3 = REG2MUX_6   ;
                MUX2OPU_4 = REG2MUX_7   ;
                MUX2OPU_5 = REG2MUX_8   ;
                MUX2OPU_6 = REG2MUX_0   ;
                MUX2OPU_7 = REG2MUX_1   ;
                MUX2OPU_8 = REG2MUX_2   ;
            end
            
            3'b100 : begin
                MUX2OPU_0 = REG2MUX_6   ;
                MUX2OPU_1 = REG2MUX_7   ;
                MUX2OPU_2 = REG2MUX_8   ;
                MUX2OPU_3 = REG2MUX_0   ;
                MUX2OPU_4 = REG2MUX_1   ;
                MUX2OPU_5 = REG2MUX_2   ;
                MUX2OPU_6 = REG2MUX_3   ;
                MUX2OPU_7 = REG2MUX_4   ;
                MUX2OPU_8 = REG2MUX_5   ;
            end
            
            3'b101 : begin
                MUX2OPU_0 = REG2MUX_7   ;
                MUX2OPU_1 = REG2MUX_8   ;
                MUX2OPU_2 = REG2MUX_6   ;
                MUX2OPU_3 = REG2MUX_1   ;
                MUX2OPU_4 = REG2MUX_2   ;
                MUX2OPU_5 = REG2MUX_0   ;
                MUX2OPU_6 = REG2MUX_4   ;
                MUX2OPU_7 = REG2MUX_5   ;
                MUX2OPU_8 = REG2MUX_3   ;
            end
            
            default : begin
                MUX2OPU_0 = REG2MUX_0   ;
                MUX2OPU_1 = REG2MUX_1   ;
                MUX2OPU_2 = REG2MUX_2   ;
                MUX2OPU_3 = REG2MUX_3   ;
                MUX2OPU_4 = REG2MUX_4   ;
                MUX2OPU_5 = REG2MUX_5   ;
                MUX2OPU_6 = REG2MUX_6   ;
                MUX2OPU_7 = REG2MUX_7   ;
                MUX2OPU_8 = REG2MUX_8   ;
            end
            
        endcase
    end
endmodule
