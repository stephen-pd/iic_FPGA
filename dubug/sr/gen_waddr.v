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
) (
    input           SYS_CLK             ,
    input           SYS_NRST            ,
    input           data_sop_i          ,
    input           data_vld_i          ,
    input           wready_i            ,//tell sram can be wrote
    input   [AW-1:0]wraddr_start_i      ,

    input   [5 : 0] pic_size_i          ,
    input           padding_i           ,
    input   [3 : 0] mode_i              ,
    input           wbank_update_i      ,

    output  [AW+1:0]waddr_o       

);
    //===========================================
    // description: input signal preprocess
    wire            data_sop        ;
    wire            data_vld        ;
    wire            wready          ;
    wire  [AW-1 :0] wraddr_start    ;

    wire  [5    :0] pic_size        ;
    wire            padding         ;
    wire  [3    :0] mode            ;
    wire            wbank_update    ;

    assign  data_sop        = data_sop_i        ;
    assign  data_vld        = data_vld_i        ;
    assign  wready          = wready_i          ;
    assign  wraddr_start    = wraddr_start_i    ;

    assign  pic_size        = pic_size_i        ;   
    assign  padding         = padding_i         ;
    assign  mode            = mode_i            ;
    assign  wbank_update    = wbank_update_i    ; 
    //===========================================
    // description: output signal preprocess
    reg   [AW+1 :0] r_waddr    ;

    assign  waddr_o         = r_waddr           ;
    //===========================================
    // description: gen waddr 
    always @(posedge SYS_CLK or negedge SYS_NRST) begin//waddr[11:10] sel bank , 00 sel bank0, 01 sel bank1, 10 sel bank2
        if (!SYS_NRST) begin
            r_waddr[AW+1 -: 2]  <= 'b0;
        end else begin
            if (((r_waddr[AW+1 -: 2] == 2'b10)&wbank_update) || data_sop) begin//data sop keep next input is bank0 start
                r_waddr[AW+1 -: 2]  <= 'b0                          ;
            end else if (wbank_update) begin
                r_waddr[AW+1 -: 2]  <= r_waddr[AW+1 -: 2] + 1'b1    ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin//waddr[9:0],addr in a bank
        if (!SYS_NRST) begin
            r_waddr[AW-1 : 0] <= wraddr_start ;
        end else begin
            if (data_sop) begin
                r_waddr[AW-1 :0] <= wraddr_start + (padding ? pic_size<<3 : 0)   ;//consider padding      
            end else if (wbank_update) begin//data sop keep next input is bank0 start at ERADDR_START
                r_waddr[AW-1 :0] <= wraddr_start    ;
            end else if (data_vld & wready) begin//
                r_waddr[AW-1 :0] <= r_waddr + 1'b1  ;
            end
        end
    end
  
endmodule