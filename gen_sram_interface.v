`define SIM 1
module gen_sram_interface #(
    parameter AW = 10   ,
    parameter DW = 128
) (
    input               SYS_CLK         ,
    input               SYS_NRST         ,
    input   [3    :0]   mode_i          ,
    input               r2wrsram_i      ,//sram start in state of write and read both
    input               wrsram_bank_change_i  ,//sram state change in write and read both
    input               data_sop_i      ,
    input               DATA_EOP        ,
    input   [DW-1 :0]   wdata_i         ,
    input               wdata_vld_i     ,
    input   [AW+1: 0]   waddr_i         , 
    input               rsram2idle_i    ,
  //  input   [7:0]PIC_SIZE        ,

    input   [AW+1: 0]   raddr_i         ,
    input               raddr_vld_i     ,
    
    
    input               r2bank_done_i   ,//reg rec two bank done
    input               wr2rsram_i      ,//sram state from wr to only read
    input               wsram_2line     ,

    output  [DW-1 : 0]  rdata_o         ,
    output              rdata_vld_o     ,
    output  [3:0]       sram_status_o              

    // output  reg[2 : 0] CEN ,
    // output  reg[2 : 0] WEN ,
    // output  reg[11: 0] A0  ,
    // output  reg[11: 0] A1  ,
    // output  reg[11: 0] A2  
    // output  reg[127: 0] DIN0  ,//SRAM wdata INPUT
    // output  reg[127: 0] DIN1  ,
    // output  reg[127: 0] DIN2  
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

    reg [1:0]rbank_sel      ;

    wire cnn_mode                           ;
    wire full_connect_mode                  ;

    wire    [DW-1 : 0]DOUT0               ;
    wire    [DW-1 : 0]DOUT1               ;
    wire    [DW-1 : 0]DOUT2               ;
    reg     [DW-1 : 0]DOUT                ;


    localparam FSM_IDLE     = 4'b0001   ;
    localparam FSM_WSRAM    = 4'b0010   ;
    localparam FSM_RSRAM    = 4'b0100   ;
    localparam FSM_WRSRAM   = 4'b1000   ;

    //===========================================
    // description: input signal preprocess  
    wire    [3  :0] mode            ;
    wire            r2wrsram        ;
    wire            wrsram_bank_change    ;
    wire            data_sop        ;
    wire    [DW-1:0]wdata           ;
    wire            wdata_vld       ;
    wire    [AW+1:0]waddr           ;
    wire    [AW+1:0]raddr           ;
    wire            raddr_vld       ;
    wire            r2bank_done     ;
    wire            wr2rsram        ;
    wire            rsram2idle      ;

    assign  cnn_mode = mode[0] || mode[1] || mode[2]    ;
    assign  full_connect_mode = mode[3]                 ;

    assign  mode            =   mode_i                  ;        
    assign  r2wrsram        =   r2wrsram_i              ;
    assign  wrsram_bank_change    =   wrsram_bank_change_i          ;
    assign  data_sop        =   data_sop_i              ;
    assign  wdata           =   wdata_i                 ;
    assign  wdata_vld       =   wdata_vld_i             ;
    assign  waddr           =   waddr_i                 ;
    assign  raddr           =   raddr_i                 ;
    assign  raddr_vld       =   raddr_vld_i             ;
    assign  r2bank_done     =   r2bank_done_i           ;
    assign  wr2rsram        =   wr2rsram_i              ;    
    assign  rsram2idle      =   rsram2idle_i            ;

    //===========================================
    // description: output signal preprocess 
    reg             rdata_vld                           ;

    assign rdata_o          = DOUT                      ;
    assign rdata_vld_o      = rdata_vld                 ; 

    assign sram_status_o    = fsm_sram_cstate           ;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            rdata_vld   <= 'b0                          ;
        end else begin
            rdata_vld   <= raddr_vld                    ;
        end
    end



//===========================================
// description: fsm state for 3 banks state in read or write
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
            if (data_sop)begin
                fsm_sram_nstate    = FSM_WSRAM     ;
            end else begin
                fsm_sram_nstate    = FSM_IDLE      ;
            end 
        end

        FSM_WSRAM : begin
            if (cnn_mode & r2wrsram)begin
                fsm_sram_nstate     = FSM_WRSRAM            ;
            end else if (full_connect_mode & DATA_EOP)begin
                fsm_sram_nstate     = FSM_RSRAM             ;
            end else begin
                fsm_sram_nstate     = FSM_WSRAM            ;
            end
        end

        FSM_RSRAM : begin
            if (rsram2idle)begin
                fsm_sram_nstate     = FSM_IDLE              ;
            end else begin
                fsm_sram_nstate     = FSM_RSRAM             ;
            end
        end

        FSM_WRSRAM : begin
            if (wr2rsram & cnn_mode)begin
                fsm_sram_nstate     = FSM_RSRAM             ;
            end else begin
                fsm_sram_nstate     = FSM_WRSRAM            ;
            end
        end

        default : fsm_sram_nstate   = FSM_IDLE              ;
    endcase
end

// always @(posedge SYS_CLK or negedge SYS_NRST) begin//count the number of line being read in sram
//     if (!SYS_NRST) begin
//         r_cnt_rline <= 'b0  ;
//     end else begin
//         if (r2wrsram) begin
//             r_cnt_rline <= 4    ;
//         end else if (wrsram_bank_change)begin
//             r_cnt_rline <= r_cnt_rline + 2  ;
//         end
//     end
// end
// assign s_cnt_rline_eq_N = (r_cnt_rline == PIC_SIZE) & wrsram_bank_change ;

//===========================================
// description: generate sram interface for 3 sram
always @(posedge SYS_CLK or negedge SYS_NRST ) begin
    if (!SYS_NRST) begin
        CEN <= 'b0  ;
        WEN <= 'b0  ;
    end else begin
        if (data_sop) begin//start write
            CEN <= 3'b001   ;
            WEN <= 3'b001   ;//write bank 0
        end else if (cnn_mode & r2wrsram) begin//start write and read in cnn
            CEN <= 3'b111   ;
            WEN <= 3'b100   ;//write bank2 ,read bank 0,1
        end else if (full_connect_mode & DATA_EOP) begin//start read in full_connet
            CEN <= 3'b001   ;
            WEN <= 3'b000   ;//start read bank 0
        end else if ((fsm_sram_cstate == FSM_WSRAM)&wsram_2line || (fsm_sram_cstate == FSM_WRSRAM)&wrsram_bank_change || (fsm_sram_cstate==FSM_RSRAM)&r2bank_done ) begin
            CEN <= {CEN[1] ,CEN[0] ,CEN[2]} ;
            WEN <= {WEN[1] ,WEN[0] ,WEN[2]} ;
        end else if (fsm_sram_cstate == FSM_IDLE) begin
            CEN <= 'b0  ;
            WEN <= 'b0  ;
        end 
    end
end

always @(*)begin
    if (CEN[0] & WEN[0] & (waddr[AW+1 -: 2]==2'b00) & wdata_vld) begin//add vld write
        A0 = waddr[AW-1 : 0]    ;
        DIN0 = wdata               ;
     //   rbank_sel = 'b0         ;
    end else if (CEN[0] & !WEN[0] & (raddr[AW+1 -: 2]==2'b00) & raddr_vld)begin//add vld read 
        A0 = raddr[AW-1 : 0]    ;
        DIN0 = 0                  ;
    //    rbank_sel = 1'b1        ;
    end else begin
        A0 = 'b0                ;
        DIN0 = 'B0                ;
     //   rbank_sel = 'b0         ;
    end
end

always @(*)begin
    if (CEN[1] & WEN[1] & (waddr[AW+1 -: 2]==2'b01) & wdata_vld) begin
        A1 = waddr[AW-1 : 0]    ;
        DIN1 = wdata               ;
      //  rbank_sel = 'b0         ;
    end else if (CEN[1] & !WEN[1] & (raddr[AW+1 -: 2]==2'b01) & raddr_vld)begin
        A1 = raddr[AW-1 : 0]    ;
        DIN1 = 'b0                ;
      //  rbank_sel = 1'b1        ;
    end else begin
        A1 = 'b0                ;
        DIN1 = 'b0                ;
      //  rbank_sel = 'b0         ;
    end
end

always @(*)begin
    if (CEN[2] & WEN[2] & (waddr[AW+1 -: 2]==2'b10) & wdata_vld) begin
        A2 = waddr[AW-1 : 0]    ;
        DIN2 = wdata               ;
      //  rbank_sel = 'b0         ;
    end else if (CEN[2] & !WEN[2] & (raddr[AW+1 -: 2]==2'b10))begin
        A2 = raddr[AW-1 : 0]    ;
        DIN2 = 'b0                ;
      //  rbank_sel = 1'b1        ;
    end else begin
        A2 = 'b0                ;
        DIN2 = 'b0                ;
      //  rbank_sel = 'b0         ;
    end
end

always @(posedge SYS_CLK or negedge SYS_NRST ) begin
    if (!SYS_NRST) begin
        rbank_sel <= 'b0    ;
    end else begin
        rbank_sel <= raddr[11:10]   ;
    end
    
end

`ifdef SIM
    sram_sim U_sram0_sim (
        .clk    (SYS_CLK),
        .addr   (A0),
        .din    (DIN0),
        .ce     (CEN[0]),
        .we     (WEN[0]),
        .dout   (DOUT0)
    );

    sram_sim U_sram1_sim (
        .clk    (SYS_CLK),
        .addr   (A1),
        .din    (DIN1),
        .ce     (CEN[1]),
        .we     (WEN[1]),
        .dout   (DOUT1)
    );

    sram_sim U_sram2_sim (
        .clk    (SYS_CLK),
        .addr   (A2),
        .din    (DIN2),
        .ce     (CEN[2]),
        .we     (WEN[2]),
        .dout   (DOUT2)
    );
   
`else 
     //bank0
    sram_1024_32 U_sram00_1024_32 (
        .Q      (DOUT0[32*4-1 :32*3]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
        .A      (A0                     ),//addr input 10bit
        .D      (DIN0 [32*4-1 :32*3]    )//data in 32bit
    );
    sram_1024_32 U_sram01_1024_32 (
        .Q      (DOUT0[32*3-1 :32*2]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
        .A      (A0                     ),//addr input 10bit
        .D      (DIN0 [32*3-1 :32*2]    )//data in 32bit
    );
    sram_1024_32 U_sram02_1024_32 (
        .Q      (DOUT0[32*2-1 :32*1]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
        .A      (A0                     ),//addr input 10bit
        .D      (DIN0 [32*2-1 :32*1]    )//data in 32bit
    );
    sram_1024_32 U_sram03_1024_32 (
        .Q      (DOUT0[32*1-1 :0   ]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[0]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[0]                ),//when 1 read data , when 0 write data
        .A      (A0                     ),//addr input 10bit
        .D      (DIN0 [32*1-1 :0   ]    )//data in 32bit
    );

    //bank1
    sram_1024_32 U_sram10_1024_32 (
        .Q      (DOUT1[32*4-1 :32*3]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
        .A      (A1                     ),//addr input 10bit
        .D      (DIN1 [32*4-1 :32*3]    )//data in 32bit
    );
    sram_1024_32 U_sram11_1024_32 (
        .Q      (DOUT1[32*3-1 :32*2]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
        .A      (A1                     ),//addr input 10bit
        .D      (DIN1 [32*3-1 :32*2]    )//data in 32bit
    );
    sram_1024_32 U_sram12_1024_32 (
        .Q      (DOUT1[32*2-1 :32*1]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
        .A      (A1                     ),//addr input 10bit
        .D      (DIN1 [32*2-1 :32*1]    )//data in 32bit
    );
    sram_1024_32 U_sram13_1024_32 (
        .Q      (DOUT1[32*1-1 :0   ]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[1]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[1]                ),//when 1 read data , when 0 write data
        .A      (A1                     ),//addr input 10bit
        .D      (DIN1 [32*1-1 :0   ]    )//data in 32bit
    );

    //bank2
    sram_1024_32 U_sram20_1024_32 (
        .Q      (DOUT2[32*4-1 :32*3]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
        .A      (A2                     ),//addr input 10bit
        .D      (DIN2 [32*4-1 :32*3]    )//data in 32bit
    );
    sram_1024_32 U_sram21_1024_32 (
        .Q      (DOUT2[32*3-1 :32*2]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
        .A      (A2                     ),//addr input 10bit
        .D      (DIN2 [32*3-1 :32*2]    )//data in 32bit
    );
    sram_1024_32 U_sram22_1024_32 (
        .Q      (DOUT2[32*2-1 :32*1]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
        .A      (A2                     ),//addr input 10bit
        .D      (DIN2 [32*2-1 :32*1]    )//data in 32bit
    );
    sram_1024_32 U_sram23_1024_32 (
        .Q      (DOUT2[32*1-1 :0   ]    ),//out 32 bit
        .CLK    (SYS_CLK                ),
        .CEN    (!CEN[2]                ),//when 1 disable in, when 0 eable in
        .WEN    (!WEN[2]                ),//when 1 read data , when 0 write data
        .A      (A2                     ),//addr input 10bit
        .D      (DIN2 [32*1-1 :0   ]    )//data in 32bit
    );

`endif 

    always @(*) begin
        case (rbank_sel) 

        2'b00 : DOUT = DOUT0  ;
        2'b01 : DOUT = DOUT1  ;
        2'b10 : DOUT = DOUT2  ;
        default : DOUT = 'b0    ;

        endcase
    end

    
endmodule