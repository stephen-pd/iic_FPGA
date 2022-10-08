module mux_8_1 #(
    parameter dw = 128
) (
    input   [dw*9-1 : 0]mux_8_1_in_0    ,
    input   [dw*9-1 : 0]mux_8_1_in_1    ,
    input   [dw*9-1 : 0]mux_8_1_in_2    ,
    input   [dw*9-1 : 0]mux_8_1_in_3    ,
    input   [dw*9-1 : 0]mux_8_1_in_4    ,
    input   [dw*9-1 : 0]mux_8_1_in_5    ,
    input   [dw*9-1 : 0]mux_8_1_in_6    ,
    input   [dw*9-1 : 0]mux_8_1_in_7    ,

    input   [2    : 0]  mux_8_1_ctrl    ,

    output  [dw*9-1 : 0]mux_8_1_out
);

    reg [dw*9-1 :0]r_mux_8_1_out;

    assign mux_8_1_out = r_mux_8_1_out;

    always @(*) begin
        case (mux_8_1_ctrl) 

        3'd0 : r_mux_8_1_out = mux_8_1_in_0  ;
        3'd1 : r_mux_8_1_out = mux_8_1_in_1  ;
        3'd2 : r_mux_8_1_out = mux_8_1_in_2  ;
        3'd3 : r_mux_8_1_out = mux_8_1_in_3  ;
        3'd4 : r_mux_8_1_out = mux_8_1_in_4  ;
        3'd5 : r_mux_8_1_out = mux_8_1_in_5  ;
        3'd6 : r_mux_8_1_out = mux_8_1_in_6  ;
        3'd7 : r_mux_8_1_out = mux_8_1_in_7  ;

        default : r_mux_8_1_out = mux_8_1_in_0  ;       
        endcase
    end
endmodule