module sync_register (
    input       SYS_CLK     ,
    input       SYS_NRST    ,

    input       raddr_rst_i         ,    
    input       [3  :0]ctrl_regnum_sel_i   ,
    input       [2  :0]ctrl_regbit_sel_i   ,

    output      rdata_rst_o         ,
    output      [2  :0]rdata_regbit_o,
    output      [3  :0]rdata_regnum_o   
);


    reg     rdata_rst       ;
    reg     [3  :0]rdata_regnum    ;

    assign  rdata_rst_o     = rdata_rst     ;
    assign  rdata_regnum_o  = rdata_regnum  ;
    assign  rdata_regbit_o  = ctrl_regbit_sel_i;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            rdata_rst   <=  'b0 ;
            rdata_regnum<=  'b0 ;
        end else begin
            rdata_rst   <=  raddr_rst_i ;
            rdata_regnum<=  ctrl_regnum_sel_i   ;
        end
    end
    
endmodule