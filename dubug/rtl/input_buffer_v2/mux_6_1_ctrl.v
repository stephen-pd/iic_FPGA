module mux_6_1_ctrl (
    input   SYS_CLK ,
    input   SYS_NRST,

    input   mux_6_1_ctrl_update,
    input   mux_6_1_ctrl_reset,//conside mode1

    input   [3:0]mode,

    output  [2:0]mux_6_1_ctrl
);

    reg [3:0]r_cnt_update;
    reg [2:0]r_mux_6_1_ctrl;

    assign mux_6_1_ctrl = r_mux_6_1_ctrl;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_update <= 'b0;
        end
        else begin
            if (mux_6_1_ctrl_reset)begin
                r_cnt_update <= 'b0;
            end
            else if( (r_cnt_update == 4'd11) & mux_6_1_ctrl_update & mode[0] )begin
                r_cnt_update <= 'b0;
            end
            else if( (r_cnt_update == 4'd2) & mux_6_1_ctrl_update & (mode[1]||mode[2]) )begin
                r_cnt_update <= 'b0;
            end
            else if(mux_6_1_ctrl_update)begin
                r_cnt_update <= r_cnt_update + 1'b1;
            end
        end
    end

    always @(*) begin
        if (mode[0]) begin//mode0
            case (r_cnt_update)

            4'd0 : r_mux_6_1_ctrl  = 3'd0   ;
            4'd1 : r_mux_6_1_ctrl  = 3'd1   ;
            4'd2 : r_mux_6_1_ctrl  = 3'd2   ;
            4'd3 : r_mux_6_1_ctrl  = 3'd3   ;
            4'd4 : r_mux_6_1_ctrl  = 3'd4   ;
            4'd5 : r_mux_6_1_ctrl  = 3'd5   ;
            4'd6 : r_mux_6_1_ctrl  = 3'd1   ;
            4'd7 : r_mux_6_1_ctrl  = 3'd0   ;
            4'd8 : r_mux_6_1_ctrl  = 3'd3   ;
            4'd9 : r_mux_6_1_ctrl  = 3'd2   ;
            4'd10: r_mux_6_1_ctrl  = 3'd5   ;
            4'd11: r_mux_6_1_ctrl  = 3'd4   ;
            default : r_mux_6_1_ctrl  = 3'd0;
            endcase 
        end else if (mode[1]||mode[2]) begin//mode1
            case (r_cnt_update)
            
            4'd0 : r_mux_6_1_ctrl  = 3'd0   ;
            4'd1 : r_mux_6_1_ctrl  = 3'd3   ;
            4'd2 : r_mux_6_1_ctrl  = 3'd4   ; 
            default: r_mux_6_1_ctrl  = 3'd0   ;
            endcase
            
        end else  begin//mode2
            r_mux_6_1_ctrl          = 'b0   ;
        end 
        
    end
endmodule