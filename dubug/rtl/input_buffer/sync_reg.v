module sync_reg (
    input       SYS_CLK     ,
    input       SYS_NRST    ,

    input       raddr_rst_i         ,    
    input       raddr_vld_i         ,
    input       [3  :0]ctrl_regnum_sel_i   ,

    output      rdata_rst_o         ,
    output      rdata_vld_o         ,
    output      [3  :0]rdata_regnum_o   
);


    reg     rdata_rst       ;
    reg     rdata_vld       ;
    reg     [3  :0]rdata_regnum    ;

    assign  rdata_rst_o     = rdata_rst     ;
    assign  rdata_vld_o     = rdata_vld     ;
    assign  rdata_regnum_o  = rdata_regnum  ;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            rdata_rst   <=  'b0 ;
            rdata_vld   <=  'b0 ;
            rdata_regnum<=  'b0 ;
        end else begin
            rdata_rst   <=  raddr_rst_i ;
            rdata_vld   <=  raddr_vld_i ;
            rdata_regnum<=  ctrl_regnum_sel_i   ;
        end
    end
    
endmodule