// +FHEADER ==================================================
// FilePath       : \sr\gen_waddr.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-09-01 16:18:45
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-18 19:02:57
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module gen_waddr #(
    parameter AW = 10  
   // parameter DW = 128
) (
    input           SYS_CLK     ,
    input           SYS_RST     ,
  //  input [DW-1:0]DATA  ,
    input           DATA_SOP    ,
  //  input           DATA_HSYNC  ,
    input           DATA_VLD    ,
    input           WREADY      ,//tell sram can be wrote
    input   [AW-1:0]WRADDR_START,

    input   [7 : 0] PIC_SIZE    ,
    input           PADDING     ,
    input   [3 : 0] MODE        ,
    input           WBANK_UPDATE    ,

    output  [AW+1:0]WADDR       
    // output TWO_BANK_FULL,
    // output ONE_BANK_FULL

);

    // reg [7:0]r_cnt_hsync        ;//count hsync number
    reg     [AW+1 :0]r_waddr    ;
    //wire s_waddr_eq_banlkend    ;//in full connected , write one bank full
    

    assign WADDR = r_waddr      ;

    always @(posedge SYS_CLK or negedge SYS_RST) begin//waddr[11:10] sel bank , 00 sel bank0, 01 sel bank1, 10 sel bank2
        if (!SYS_RST) begin
            r_waddr[AW+1 -: 2]  <= 'b0;
        end else begin
            if (((r_waddr[AW+1 -: 2] == 2'b10)&WBANK_UPDATE) || DATA_SOP) begin//data sop keep next input is bank0 start
                r_waddr[AW+1 -: 2]  <= 'b0                        ;
            end else if (WBANK_UPDATE ) begin
                r_waddr[AW+1 -: 2]  <= r_waddr[AW+1 -: 2] + 1'b1    ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin//waddr[9:0],addr in a bank
        if (!SYS_RST) begin
            r_waddr[AW-1 : 0] <= WRADDR_START ;
        end else begin
            if (DATA_SOP) begin
                r_waddr[AW-1 :0] <= WRADDR_START + (PADDING ? PIC_SIZE * 8 : 0)   ;//consider padding      
            end else if ((WBANK_UPDATE& !MODE[3])) begin//data sop keep next input is bank0 start at ERADDR_START
                r_waddr[AW-1 :0] <= WRADDR_START  ;
            end else if (DATA_VLD & WREADY) begin//
                r_waddr[AW-1 :0] <= r_waddr + 1'b1  ;
            end
        end
    end
  //  assign s_waddr_eq_banlkend = (r_waddr[AW-1 :0] == (1<<AW)-1 ) & DATA_VLD & WREADY  ;


    
endmodule