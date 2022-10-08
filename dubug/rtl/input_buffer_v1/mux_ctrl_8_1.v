module mux_ctrl_8_1 (
    input   SYS_CLK         ,
    input   SYS_NRST        ,

    input   reg_out_i       ,
    output  [2 : 0]ctrl_mux_8_1_o,
    output   regout_matrix_o
);

    reg  [2 :0] r_cnt_reg_out   ;
    
    assign ctrl_mux_8_1_o = r_cnt_reg_out   ;
    assign regout_matrix_o = (r_cnt_reg_out == 3'd7)&reg_out_i  ;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_reg_out   <= 'b0  ;
        end else begin
            if (reg_out_i) r_cnt_reg_out  <= r_cnt_reg_out +  1'b1    ;
        end
    end
    
endmodule