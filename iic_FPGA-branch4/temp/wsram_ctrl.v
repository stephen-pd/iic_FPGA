// +FHEADER ==================================================
// FilePath       : \sr\wsram_ctrl.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-24 10:53:11
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-08-29 13:20:34
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
module wsram_ctrl #(
    parameters AW = 10 ;
)(
    input data_sop,
    input data_eop,
    input data[127:0],
    input data_valid,
    input data_hsync,
    input data_vsync,
    input data_eop  ,

    input padding   ,

    input data_start_wraddr[AW-1:0],

    input MODE[3:0],//[0]three direction mode ,[1]line mode stride=1 , [2]line mode stride=2 , [3]full-connected 
    
    input SYS_CLK,
    input SYS_NRST,

    input 

    input wsram_ready,//when 1, can write data to sram

//output bank_status[2:0],//when bank1 and bank2 flushed [110]，when bank2 and bank3 flushed [011]
    output bank_ok  ,

    output 
);

    reg [3:0] fsm_sram_cstate           ;
    reg [3:0] fsm_sram_nstate           ;
    reg [7:0] r_cnt_data_wsram          ;
    reg [AW+1 : 0] r_ctrl2sram_waddr    ;
    reg [7:0] r_cnt_hsync_wsram         ;

    wire s_cnt_data_wsram_eq_2line      ;
 //   wire s_cnt_data_wsram_eq_end        ;
    wire s_cnt_hsync_wsram_eq_2line     ;
    wire s_ctrl2sram_waddr_eq_end       ;
    wire full_connect_mode              ;
    wire full_mode                      ;
    wire s_wsram_2bank                  ;
    wire [2:0] CEN                      ;
    wire [2:0] WEN                      ;

    localparam FSM_IDLE     = 4'b0001   ;
    localparam FSM_WSRAM    = 4'b0010   ;
    localparam FSM_RSRAM    = 4'b0100   ;
    localparam FSM_WRSRAM   = 4'b1000   ;

    always @(posedge SYS_CLK ) begin//count hsync data to sram, include the padding situation 
        if (!SYS_NRST) r_cnt_hsync_wsram <= 'b0;
        else begin
            if (data_sop)        r_cnt_hsync_wsram <= {5'b0 , padding}          ;
            else if (data_hsync) r_cnt_hsync_wsram <= r_cnt_hsync_wsram + 1'b1  ;
        end
    end
    assign s_cnt_hsync_wsram_eq_2line = r_cnt_hsync_wsram[0] & data_hsync       ;//bank write change signal
    

    always @(posedge SYS_CLK) begin//waddr[9:0] in a bank
        if (!SYS_NRST) r_ctrl2sram_waddr[AW-1 : 0] <= data_start_wraddr  ;
        else begin
            if ((s_ctrl2sram_waddr_eq_end&MODE[3]) || (s_cnt_hsync_wsram_eq_2line&(!MODE[3])))begin
                r_ctrl2sram_waddr[AW-1 : 0]     <= data_start_wraddr    ;
            end else if (data_valid) begin
                r_ctrl2sram_waddr[AW-1 : 0]     <= r_ctrl2sram_waddr[AW-1 : 0] + 1'b1   ;
            end
        end
    end
    assign s_ctrl2sram_waddr_eq_end  = (r_ctrl2sram_waddr[AW-1 : 0] == (1 << AW)-1 ) & data_valid ;

    always @(posedge SYS_CLK or posedge SYS_NRST) begin//waddr[11:0] sel bank , 00 sel bank0, 01 sel bank1, 10 sel bank2
        if (!SYS_NRST) begin
            r_ctrl2sram_waddr[AW+1 -: 2]  <= 'b0;
        end else begin
            if ((r_ctrl2sram_waddr[AW+1 -: 2] == 2'b10)&s_cnt_hsync_wsram_eq_2line) begin
                r_ctrl2sram_waddr[AW+1 -: 2]  <= 'b0    ;
            end else if (s_cnt_hsync_wsram_eq_2line) begin
                r_ctrl2sram_waddr[AW+1 -: 2]  <= r_ctrl2sram_waddr[AW+1 -: 2] + 1'b1    ;
            end
        end
    end
///////////FSM STATE , sram state////////////
    assign full_connect_mode    = MODE[3]  ;
    assign cnn_mode             = MODE[0] || MODE[1] || MODE[2] ;
    assign s_wsram_2bank        = (r_cnt_hsync_wsram == 4 -1)&data_hsync    ;

    always @(posedge SYS_CLK) begin
        if (!SYS_NRST) begin
            fsm_sram_cstate <= FSM_IDLE ;
        end else begin
            fsm_sram_cstate <= fsm_sram_nstate  ;
        end
    end

    always @(*) begin
        case (fsm_sram_nstate)
            FSM_IDLE : begin
                if (data_sop) fsm_sram_nstate = FSM_WSRAM   ; 
            end

            FSM_WSRAM : begin
                if (cnn_mode & s_wsram_2bank) fsm_sram_nstate = FSM_WRSRAM          ;
                else if (full_connect_mode & data_eop) fsm_sram_nstate = FSM_RSRAM  ;
            end

            FSM_RSRAM : begin
                if () fsm_sram_nstate = FSM_IDLE    ;
            end

            FSM_WRSRAM : begin
                if () fsm_sram_nstate = FSM_RSRAM   ;
            end

            default : fsm_sram_nstate = FSM_IDLE
        endcase
    end
    
    always @(*)begin
        if (CEN0 & WEN0 & (r_ctrl2sram_waddr[AW+1 -: 2]==2'b00)) begin
            A0 = r_ctrl2sram_waddr[AW-1 : 0]    ;
        end else if (CEN0 & !WEN0 & (r_ctrl2sram_raddr[AW+1 -: 2]==2'b00))begin
            A0 = r_ctrl2sram_raddr[AW-1 : 0]    ;
        end else begin
            A0 = 'b0 ;
        end
    end

    always @(*)begin
        if (CEN1 & WEN1 & (r_ctrl2sram_waddr[AW+1 -: 2]==2'b01)) begin
            A1 = r_ctrl2sram_waddr[AW-1 : 0]    ;
        end else if (CEN1 & !WEN1 & (r_ctrl2sram_raddr[AW+1 -: 2]==2'b01))begin
            A1 = r_ctrl2sram_raddr[AW-1 : 0]    ;
        end else begin
            A1 = 'b0 ;
        end
    end

    always @(*)begin
        if (CEN2 & WEN2 & (r_ctrl2sram_waddr[AW+1 -: 2]==2'b10)) begin
            A2 = r_ctrl2sram_waddr[AW-1 : 0]    ;
        end else if (CEN2 & !WEN2 & (r_ctrl2sram_raddr[AW+1 -: 2]==2'b10))begin
            A2 = r_ctrl2sram_raddr[AW-1 : 0]    ;
        end else begin
            A2 = 'b0 ;
        end
    end

    assign {CEN2 , CEN1 , CEN0} = CEN  ;
    assign {WEN2 , WEN1 , WEN0} = WEN  ;
    always @(posedge SYS_CLK or posedge SYS_NRST ) begin
        if (!SYS_NRST) begin
            CEN <= 'b0  ;
            WEN <= 'b0  ;
        end else begin
            if (fsm_sram_cstate == FSM_IDLE) begin
                CEN <= 'b0  ;
                WEN <= 'b0  ; 
            end else if (data_sop) begin//start write
                CEN <= 3'b001   ;
                WEN <= 3'b001   ;
            end else if (cnn_mode & s_wsram_2bank) begin//start write and read in cnn
                CEN <= 3'b111   ;
                WEN <= 3'b100   ;//write bank2 ,read bank 0,1
            end else if (full_connect_mode & data_eop) begin//start read in full_connet
                CEN <= 3'b001   ;
                WEN <= 3'b000   ; 
            end else if ((fsm_sram_cstate == FSM_WSRAM)&s_cnt_hsync_wsram_eq_2line || (fsm_sram_cstate == FSM_WRSRAM)& ) begin//not include bank change in full connected
                CEN <= {CEN[1] ,CEN[0] ,CEN[2]} ;
                WEN <= {WEN[1] ,WEN[0] ,WEN[2]} ;
            end
        end
    end



    
endmodule