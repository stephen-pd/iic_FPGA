1// +FHEADER ==================================================
// FilePath       : \sr\gen_mux_1_9_ctrl.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-09-03 16:13:29
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-03 18:00:45
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module gen_mux_1_9_ctrl #(
    parameters
) (
   input    SYS_CLK ;
   input    SYS_NRST ;
   input    

   output   [3:0]CTRL_REGNUM_SEL    ;
);

   reg [3 : 0]lut_x ;
   reg [1 : 0]lut_y ;
   reg [11 : 0]lut_row_out  ;
   reg [3 : 0]lut_out       ;


   //===========================================
   // description: lut for mux1_9 select signal


   //===========================================
   // description: lut ctrl signal






endmodule