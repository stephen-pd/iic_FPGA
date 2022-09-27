module gen_sram_interface #(
    parameter AW = 10   ,
    parameter DW = 128
) (
    input               SYS_CLK         ,
    input               SYS_NRST        ,

    input   [3    :0]   mode_i          ,
    input   [5    :0]   pic_size_i      ,
    input               padding_i       ,
    input               wrsram_start_i  ,//sram start in state of write and read both
  //  input               wrsram_end_i    ,
    input               wsram_2line     ,//sram state change in write 
    
    input               wsram_start_i   ,

    input   [DW-1 :0]   wdata_i         ,
    input               wdata_vld_i     ,
    input   [AW+1: 0]   waddr_i         , 

    input   [AW+1: 0]   raddr_i         ,
    input               raddr_vld_i     ,
    
    //input               rsram_start_i   ,//sram state from wr to only read
    input               rsram_done_i    ,
    

    output  [3:0]       sram_status_o   ,  

    output  [2     : 0] CEN_o           ,
    output  [2     : 0] WEN_o           ,
    output  [AW-1  : 0] A0_o            ,
    output  [AW-1  : 0] A1_o            ,
    output  [AW-1  : 0] A2_o            ,
    output  [DW-1  : 0] DIN0_o          ,//SRAM wdata INPUT
    output  [DW-1  : 0] DIN1_o          ,
    output  [DW-1  : 0] DIN2_o          
);

    reg [3:0] fsm_sram_cstate           ;
    reg [3:0] fsm_sram_nstate           ;

    reg [DW-1 :0] DIN0      ;
    reg [DW-1 :0] DIN1      ;
    reg [DW-1 :0] DIN2      ;
    reg [AW-1 :0] A0        ;
    reg [AW-1 :0] A1        ;
    reg [AW-1 :0] A2        ;

    reg [2:0]CEN            ;
    reg [2:0]WEN            ;


    wire cnn_mode                           ;
    wire full_connect_mode                  ;

    localparam FSM_IDLE     = 4'b0001   ;
    localparam FSM_WSRAM    = 4'b0010   ;
    localparam FSM_RSRAM    = 4'b0100   ;
    localparam FSM_WRSRAM   = 4'b1000   ;

    //===========================================
    // description: input signal preprocess  
    wire    [3  :0] mode            ;
    wire    [5  :0] pic_size        ;
    wire            wrsram_start    ;
    wire    [DW-1:0]wdata           ;
    wire            wdata_vld       ;
    wire    [AW+1:0]waddr           ;

    wire    [AW+1:0]raddr           ;
    wire            raddr_vld       ;
    wire            rsram_done      ;
    wire            padding         ;


    assign  cnn_mode = mode[0] || mode[1] || mode[2]    ;
    assign  full_connect_mode = mode[3]                 ;

    assign  mode            =   mode_i                  ;  
    assign  pic_size        =   pic_size_i              ;      

    assign  wrsram_start    =   wrsram_start_i          ;
    assign  wsram_start     =   wsram_start_i           ;
    assign  wdata           =   wdata_i                 ;
    assign  wdata_vld       =   wdata_vld_i             ;
    assign  waddr           =   waddr_i                 ;

    assign  raddr           =   raddr_i                 ;
    assign  raddr_vld       =   raddr_vld_i             ;
    assign  rsram_done      =   rsram_done_i            ;
    assign  padding         =   padding_i               ;

    //assign  wrsram_end      =   wrsram_end_i            ;


    //===========================================
    // description: output signal preprocess 

    assign  CEN_o   =  CEN                 ; 
    assign  WEN_o   =  WEN                 ;
    assign  A0_o    =  A0                  ;
    assign  A1_o    =  A1                  ;
    assign  A2_o    =  A2                  ;
    assign  DIN0_o  =  DIN0                ;
    assign  DIN1_o  =  DIN1                ; 
    assign  DIN2_o  =  DIN2                ;

    assign sram_status_o    = fsm_sram_cstate        ;

    //===========================================
    // description: generate s_rsram_start s_rsram2ide
    wire s_rsram2idle   ;
    wire s_rsram_start  ;
    reg [5:0]r_cnt_wrsram_start ;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin//count the number of sram2reg rdy&vld
        if (!SYS_NRST)begin
            r_cnt_wrsram_start  <= 'b0  ;
        end else begin
            if (wsram_start)begin//data_sop
                r_cnt_wrsram_start <= 'b0    ;
            end else if (wrsram_start)begin//sram2reg_rdy&vld
                r_cnt_wrsram_start <= r_cnt_wrsram_start + 1'b1 ;
            end
        end
    end

    assign s_rsram_start = (r_cnt_wrsram_start == ((pic_size>>1) - 'd2 + padding))&wrsram_start   ;
    assign s_rsram2idle  = (r_cnt_wrsram_start == ((pic_size>>1) - 'd1 + padding))&wrsram_start   ;//for prevent the situation of write slow, read fast

//===========================================
// description: fsm state for 3 banks state in read or write
    //wire    s_cfsm_idle     ;
    wire    s_cfsm_wsram    ;
    //wire    s_cfsm_rsram    ;
    //wire    s_cfsm_wrsram   ;

    //assign  s_cfsm_idle     = fsm_sram_cstate==FSM_IDLE     ;
    assign  s_cfsm_wsram    = fsm_sram_cstate==FSM_WSRAM    ;
    //assign  s_cfsm_wrsram   = fsm_sram_cstate==FSM_WRSRAM   ;
    //assign  s_cfsm_rsram    = fsm_sram_cstate==FSM_RSRAM    ;
always @(posedge SYS_CLK or negedge SYS_NRST) begin
    if (!SYS_NRST) begin
        fsm_sram_cstate <= FSM_IDLE ;
    end else begin
        fsm_sram_cstate <= fsm_sram_nstate  ;
    end
end

always @(*) begin
    case (fsm_sram_cstate)
        FSM_IDLE : begin
            if (wsram_start)begin
                fsm_sram_nstate    = FSM_WSRAM     ;
            end else begin
                fsm_sram_nstate    = FSM_IDLE      ;
            end 
        end

        FSM_WSRAM : begin
            if (cnn_mode & wrsram_start)begin
                fsm_sram_nstate     = FSM_WRSRAM            ;
            end else if (full_connect_mode & wrsram_start)begin
                fsm_sram_nstate     = FSM_RSRAM             ;
            end else begin
                fsm_sram_nstate     = FSM_WSRAM            ;
            end
        end

        FSM_RSRAM : begin
            if (s_rsram2idle)begin//read 2 bank done
                fsm_sram_nstate     = FSM_IDLE              ;
            end else begin
                fsm_sram_nstate     = FSM_RSRAM             ;
            end
        end

        FSM_WRSRAM : begin
            if (s_rsram_start & cnn_mode)begin
                fsm_sram_nstate     = FSM_RSRAM             ;
            end else begin
                fsm_sram_nstate     = FSM_WRSRAM            ;
            end
        end

        default : fsm_sram_nstate   = FSM_IDLE              ;
    endcase
end

//===========================================
// description: generate sram interface for 3 sram
always @(posedge SYS_CLK or negedge SYS_NRST ) begin
    if (!SYS_NRST) begin
        CEN <= 'b0  ;
        WEN <= 'b0  ;
    end else begin
        if (wsram_start) begin//start write
            CEN <= 3'b001   ;
            WEN <= 3'b001   ;//write bank 0
        end else if (cnn_mode & wrsram_start & s_cfsm_wsram) begin//start write and read in cnn
            CEN <= 3'b111   ;
            WEN <= 3'b100   ;//write bank2 ,read bank 0,1
        end else if (full_connect_mode & wrsram_start & s_cfsm_wsram) begin//start read in full_connet
            CEN <= 3'b001   ;
            WEN <= 3'b000   ;//start read bank 0
        end else if (s_cfsm_wsram & wsram_2line || (~s_cfsm_wsram & wrsram_start)) begin
            CEN <= {CEN[1] ,CEN[0] ,CEN[2]} ;
            WEN <= {WEN[1] ,WEN[0] ,WEN[2]} ;
        end  
    end
end

always @(*)begin
    if (CEN[0] & WEN[0] & (waddr[AW+1 -: 2]==2'b00) & wdata_vld) begin//add vld write
        A0      = waddr[AW-1 : 0]        ;
        DIN0    = wdata                  ;
    
    end else if (CEN[0] & !WEN[0] & (raddr[AW+1 -: 2]==2'b00) & raddr_vld)begin//add vld read 
        A0      = raddr[AW-1 : 0]        ;
        DIN0    = 'b0                    ;
    
    end else begin
        A0      = 'b0                    ;
        DIN0    = 'B0                    ;
    
    end
end

always @(*)begin
    if (CEN[1] & WEN[1] & (waddr[AW+1 -: 2]==2'b01) & wdata_vld) begin
        A1      = waddr[AW-1 : 0]        ;
        DIN1    = wdata                  ;
      
    end else if (CEN[1] & !WEN[1] & (raddr[AW+1 -: 2]==2'b01) & raddr_vld)begin
        A1      = raddr[AW-1 : 0]        ;
        DIN1    = 'b0                    ;
      
    end else begin
        A1      = 'b0                    ;
        DIN1    = 'b0                    ;
      
    end
end

always @(*)begin
    if (CEN[2] & WEN[2] & (waddr[AW+1 -: 2]==2'b10) & wdata_vld) begin
        A2      = waddr[AW-1 : 0]        ;
        DIN2    = wdata                  ;
      
    end else if (CEN[2] & !WEN[2] & (raddr[AW+1 -: 2]==2'b10))begin
        A2      = raddr[AW-1 : 0]        ;
        DIN2    = 'b0                    ;
      
    end else begin
        A2      = 'b0                    ;
        DIN2    = 'b0                    ;
      
    end
end

    
endmodule