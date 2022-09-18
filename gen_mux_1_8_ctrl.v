// +FHEADER ==================================================
// FilePath       : \sr\gen_mux_1_8_ctrl.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-09-01 17:32:10
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-18 16:33:22
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module gen_mux_1_8_ctrl (
    input   SYS_CLK ,
    input   SYS_RST ,
    // input   TWO_BANK_FULL   ,
    // input   ONE_BANK_FULL   ,
    input   gen_raddr_i         ,
    input   gen_raddr_hsync_i   ,

    output [2:0]CTRL_BIT_SEL    ,
    output READ_ONE_MATRIX  
);

    reg [2:0]r_ctrl_bit_sel ;
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_ctrl_bit_sel <= 'b0 ;
        end else begin
            if (GEN_RADDR_START)begin//can not judge by TWO_BANK_FULL,it is for write,but ctrl_bit_sel is for read 
                r_ctrl_bit_sel <= CTRL_BIT_SEL + 1    ;
            end
        end
    end
    assign CTRL_BIT_SEL = r_ctrl_bit_sel ;
    assign READ_ONE_MATRIX = (r_ctrl_bit_sel== 3'b111)& GEN_RADDR_START   ;
    
endmodule