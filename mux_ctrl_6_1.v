// +FHEADER ==================================================
// FilePath       : \sr\mux_ctrl_6_1.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-09-18 00:29:07
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-19 17:07:44
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module mux_ctrl_6_1 (
    input   SYS_CLK ,
    input   SYS_NRST ,
    input   [3:0]mode_i ,
    input   ctrl_update_i,
    input   ctrl_reset_i,
    input   [7:0]pic_size,
    input   padding ,

    output  [2:0]ctrl_mux_6_1
);

    reg [2:0]   r_ctrl_mux_6_1      ;
    reg [3:0]   r_reg2opu_ctrl_type ;
    wire        ctrl_update         ;
    wire [3:0]  s_mode              ;
    wire        ctrl_reset          ;

    assign ctrl_mux_6_1     = r_ctrl_mux_6_1    ;
    assign ctrl_update      = ctrl_update_i     ;
    assign s_mode           = mode_i            ;
    assign ctrl_reset       = ctrl_reset_i      ;

    reg [7:0]r_cnt_ctrl_update  ;
    wire s_ctrl_reset   ;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_ctrl_update <= 'b0    ;
        end else begin
            if (s_ctrl_reset)begin
                r_cnt_ctrl_update <= 'b0    ;
            end else if (ctrl_update)begin
                r_cnt_ctrl_update <= r_cnt_ctrl_update + 1'b1   ;
            end
        end
    end
    reg [7:0]   line_update ;
    always @(*) begin
        if (s_mode[1])begin
            line_update = pic_size - 2'd2 + 2*padding  ;
        end else if (s_mode[2])begin
            line_update = pic_size - 4'd3 + 2*padding ;
        end
    end
    assign s_ctrl_reset = (r_cnt_ctrl_update == line_update - 1'b1)&ctrl_update ;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_reg2opu_ctrl_type     <= 'b0  ;
        end else begin
            if (ctrl_reset || ((s_mode[1]||s_mode[2])&s_ctrl_reset) )begin
                r_reg2opu_ctrl_type <= 'b0  ;
            end else if ((r_reg2opu_ctrl_type == 4'd11) & ctrl_update & s_mode[0]) begin//reflect type loop OF 12 in mode0
                r_reg2opu_ctrl_type <= 'b0  ;
            end else if ((r_reg2opu_ctrl_type == 4'd2) & ctrl_update & (s_mode[1]||s_mode[2]) ) begin//REFLECT type loop of 3 in s_mode[1/2] 
                r_reg2opu_ctrl_type <= 'b0  ;
            end else if (ctrl_update) begin
                r_reg2opu_ctrl_type <= r_reg2opu_ctrl_type + 1  ;
            end
        end
    end

    always @(*) begin
        if (s_mode[0]) begin//mode0
            case (r_reg2opu_ctrl_type)

            4'd0 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd1 : r_ctrl_mux_6_1  = 3'd1   ;
            4'd2 : r_ctrl_mux_6_1  = 3'd2   ;
            4'd3 : r_ctrl_mux_6_1  = 3'd3   ;
            4'd4 : r_ctrl_mux_6_1  = 3'd4   ;
            4'd5 : r_ctrl_mux_6_1  = 3'd5   ;
            4'd6 : r_ctrl_mux_6_1  = 3'd1   ;
            4'd7 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd8 : r_ctrl_mux_6_1  = 3'd3   ;
            4'd9 : r_ctrl_mux_6_1  = 3'd2   ;
            4'd10: r_ctrl_mux_6_1  = 3'd5   ;
            4'd11: r_ctrl_mux_6_1  = 3'd4   ;
            default : r_ctrl_mux_6_1  = 3'd0;
            endcase 
        end else if (s_mode[1]||s_mode[2]) begin//mode1
            case (r_reg2opu_ctrl_type)
            
            4'd0 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd1 : r_ctrl_mux_6_1  = 3'd3   ;
            4'd2 : r_ctrl_mux_6_1  = 3'd4   ; 
            default: r_ctrl_mux_6_1  = 3'd0   ;
            endcase
            
        end else  begin//mode2
            case (r_reg2opu_ctrl_type)
            
            4'd0 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd1 : r_ctrl_mux_6_1  = 3'd4   ;
            4'd2 : r_ctrl_mux_6_1  = 3'd3   ; 
            default: r_ctrl_mux_6_1  = 3'd0 ;
            endcase
        end 
        
    end
    
endmodule