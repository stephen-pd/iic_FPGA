// +FHEADER ==================================================
// FilePath       : \sr\top.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-29 18:20:06
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-17 16:27:51
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================

module top #(
    parameter   AW  = 10,
    parameter   DW  = 128
) (
    input   SYS_CLK ,
    input   SYS_RST ,

    input   [DW-1 : 0]  DATA        ,
    input               DATA_VLD    ,
    output              WREADY      ,//sram is ready for write
    input               DATA_HSYNC  ,
    input               DATA_SOP    ,
    input   [AW-1 : 0]  WRADDR_START,

    

    input               OPU_1152_RDY,//opu compute finish
    output              OPU_1152_VLD,//reg_aray is ready for opu

    input   [7    : 0]  PIC_SIZE    ,
    input               PADDING     ,
    input   [3    : 0]  MODE        ,

    input               SRAM2REG_VLD,//start pass sram to reg
    output              SRAM2REG_RDY,

    output  [DW*9-1:0]  OPU_1152    ,
    
    input   [AW   :0]   CTRL_MUX_1152_1 ,//11bit to sel in 1152
    output  [7    :0]   REG_ARRAY_ROW,   //8bit sel from reg_array
    output  [3    :0]   SRAM_STATUS

);
    
    reg [1151 : 0]reg_array[7:0]    ;//reg array

    reg [7    : 0]r_cnt_hsync       ;//count data_hsync

  //  reg [AW+1 : 0]r_waddr           ;
    wire [AW+1 :0]s_waddr           ;//write to sram
    wire [AW+1 :0]s_raddr           ;//read from sram
   // reg           r_raddr_vld       ;
   // reg           r_raddr_rst       ;//rst register

    reg             r_wready        ;//sram ready for write
    wire            s_wready_up     ;
    wire            s_wready_dw     ;//for wready
    wire            s_r2bank_done   ;//read 2 bank to reg_array

    reg             r_sram2reg_rdy  ;//sram ready for pass to reg_array
    reg  [1:0]      r_sram2reg_rdy_temp ;
    wire            s_sram2reg_rdy_up   ;
    wire            s_sram2reg_rdy_dw   ;
//    wire            s_w1bank_full   ;//write 1 bank full 

    wire s_cnt_hsync_eq_2line       ;
    wire s_two_bank_full            ;//cnt_hsync == 3
    wire s_one_bank_full            ;//cnt_hsync > 3 & cnt_hsync==2line
    wire s_cnt_hsync_eq_N           ;//cnt_hsync == N + padding

    wire s_cnt_raddr_rec_eqsend     ;//reg array receive 9/3 data
    wire [3:0]s_num_raddr           ;//eq 9/3

    wire s_read_one_matrix          ;

    wire s_gen_addr                 ;

    

    wire [2:0]s_ctrl_bit_sel        ;//which reg bit
    wire [3:0]s_ctrl_regnum_sel     ;//which reg

    wire [DW-1 : 0]s_rdata          ;//read out from sram

    wire [2:0]  opu_bit_sel         ;

    wire        s_reg_array_full    ;

    wire        s_rdata_vld         ;
    wire [3:0]  s_sram_status       ;

    assign SRAM_STATUS = s_sram_status  ;
    


    assign WREADY = r_wready        ;
    assign SRAM2REG_RDY = r_sram2reg_rdy  ;
    //===========================================
    // description: count hsync signal
    always @(posedge SYS_CLK or negedge SYS_RST) begin//count hsync data to sram, include the padding situation 
        if (!SYS_RST) begin
            r_cnt_hsync <= 'b0;
        end else begin
            if (DATA_SOP)        r_cnt_hsync <= {6'b0 , PADDING}    ;
            else if (DATA_HSYNC) r_cnt_hsync <= r_cnt_hsync + 1'b1  ;
        end
    end
    assign s_cnt_hsync_eq_2line = r_cnt_hsync[0] & DATA_HSYNC       ;//bank write change 
    
    assign s_two_bank_full = (r_cnt_hsync == 3) & DATA_HSYNC          ;
    assign s_one_bank_full = (r_cnt_hsync > 3) & s_cnt_hsync_eq_2line ;

    assign s_cnt_hsync_eq_N = (r_cnt_hsync == PIC_SIZE -1 + PADDING)  ;


    //===========================================
    // description: wready signal
    //******(write bank 0 1 )**** **********(write bank 2)***********           *******(write bank 1)********
    //                            ************(read bank 0 1 to register)****** ********(read bank 2 to register)*****
    assign  s_wready_up =   &r_sram2reg_rdy_temp  ;
    assign  s_wready_dw =   s_one_bank_full ;//one_bank_full is write 2 line to sram ok
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_wready    <= 1'b1 ; 
        end else begin
            if (s_wready_up) begin
                r_wready    <= 1'b1 ;
            end else if (s_wready_dw) begin
                r_wready    <= 1'b0 ;
            end
        end
    end


    //===========================================
    // description: ram2reg_rdy signal
    assign s_sram2reg_rdy_up    = &r_sram2reg_rdy_temp                      ;
    assign s_sram2reg_rdy_dw    = SRAM2REG_VLD & SRAM2REG_RDY               ;
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_sram2reg_rdy_temp = 'b0   ;
        end else begin
            if (r_sram2reg_rdy_temp==2'b11)  r_sram2reg_rdy_temp    = 0  ;//down immediately
            if (s_one_bank_full)    r_sram2reg_rdy_temp[0] = 1  ;
            if (s_r2bank_done)      r_sram2reg_rdy_temp[1] = 1  ;
        end
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_sram2reg_rdy  <= 'b0  ;
        end else begin
            if (s_sram2reg_rdy_up)      r_sram2reg_rdy <= 1'b1  ;
            else if (s_sram2reg_rdy_dw) r_sram2reg_rdy <='b0    ;
        end
    end





    gen_waddr U_gen_waddr (
        .SYS_CLK            (SYS_CLK    ),
        .SYS_RST            (SYS_RST    ),
    //    .DATA               (),
        .DATA_SOP           (DATA_SOP   ),
    //    .DATA_HSYNC         (DATA_HSYNC ),
        .DATA_VLD           (DATA_VLD   ),
        .WREADY             (r_wready   ),
        .WRADDR_START       (WRADDR_START),

        .PIC_SIZE           (PIC_SIZE   ),
        .PADDING            (PADDING    ),
        .MODE               (MODE       ),
        .s_cnt_hsync_eq_2line(s_cnt_hsync_eq_2line),
        
        .WADDR              (s_waddr    )//
        // .TWO_BANK_FULL      (),
        // .ONE_BANK_FULL      ()    
    );


    gen_raddr U_gen_raddr (
        .SYS_CLK            (SYS_CLK    ),
        .SYS_RST            (SYS_RST    ),
        .gen_raddr_hsync_i      (SRAM2REG_VLD),
        .gen_raddr_sop_i      (s_two_bank_full),

        .mode_i               (MODE),////[0]three direction mode ,[1]line mode stride=1 , [2]line mode stride=2 , [3]full-connected 
        .gen_raddr_i    (s_gen_addr),
        .DATA_EOP           (DATA_EOP),
        .rec_rdata_matrix_i    (s_read_one_matrix),
        .pic_size_i           (PIC_SIZE),
        .WADDR              (s_waddr),
        .padding_i            (PADDING),
        .gen_raddr_bit_i       (s_ctrl_bit_sel),
        .wraddr_start_i       (WRADDR_START),

        .s_reg_array_full   (s_reg_array_full),

        .raddr_o              (s_raddr),
        .raddr_vld_o          (s_raddr_vld),
        .reg_rst_o            (s_raddr_rst),
        .NUM_RADDR          (s_num_raddr ),
        
        .ctrl_regnum_sel_o    (s_ctrl_regnum_sel),//gen_mux_1_9_ctrl 
        .r2bank_done_o        (s_r2bank_done)

    );



    gen_mux_1_8_ctrl U_gen_mux_1_8ctrl (
        .SYS_CLK        (SYS_CLK)  ,
        .SYS_RST        (SYS_RST)  ,
        .TWO_BANK_FULL  (s_two_bank_full) ,
        .ONE_BANK_FULL  (SRAM2REG_VLD),
        .GEN_RADDR_START(s_gen_addr),

        .CTRL_BIT_SEL   (s_ctrl_bit_sel)  ,
        .READ_ONE_MATRIX(s_read_one_matrix)  //read one matrix of 0-7bit to reg_array

    );

    gen_sram_interface U_gen_sram_interface (
        .SYS_CLK        (SYS_CLK),
        .SYS_RST        (SYS_RST),
        .mode_i           (MODE),
        .r2wrsram_i  (s_two_bank_full),
        .wrsram_bank_change_i  (SRAM2REG_VLD),
        .data_sop_i       (DATA_SOP),
        .DATA_EOP       (DATA_EOP),
        .wdata_i           (DATA),
        .wdata_vld_i       (DATA_VLD),
  //      .PIC_SIZE       (PIC_SIZE),

        .raddr_i          (s_raddr),
        .raddr_vld_i      (s_raddr_vld),
        .waddr_i          (s_waddr), 
        .r2bank_done_i    (s_r2bank_done),
        .wr2rsram_i(s_cnt_hsync_eq_N),
        .wsram_2line(s_cnt_hsync_eq_2line),

        .rdata_o              (s_rdata),
        .rdata_vld_o      (s_rdata_vld),
        .sram_status_o   (s_sram_status)
    );

    // sram_sim U_sram0_sim (
    //     .clk    (),
    //     .addr   (),
    //     .din    (),
    //     .ce     (),
    //     .we     (),
    //     .dout   ()
    // );

    // sram_sim U_sram1_sim (
    //     .clk    (),
    //     .addr   (),
    //     .din    (),
    //     .ce     (),
    //     .we     (),
    //     .dout   ()
    // );

    // sram_sim U_sram2_sim (
    //     .clk    (),
    //     .addr   (),
    //     .din    (),
    //     .ce     (),
    //     .we     (),
    //     .dout   ()
    // );

    // mux_1_9 U_mux_1_9 (
    //     .
    // );

    // mux_1_8 U_mux_1_8 (

    // );
    reg_array_fifo U_reg_array_fifo (
        .SYS_CLK        (SYS_CLK),
        .SYS_RST        (SYS_RST),

        .RDATA          (s_rdata),
        .CTRL_BIT_SEL   (s_ctrl_bit_sel),
        .CTRL_REGNUM_SEL(s_ctrl_regnum_sel),//for data to reg_array
        .RDATA_VLD      (s_rdata_vld),
        .REG_RST        (s_raddr_rst),
        .NUM_RADDR      (s_num_raddr),
        .MODE           (MODE       ),

        .OPU_1152_RDY   (OPU_1152_RDY),//input for opu compute ok

        .OPU_1152       (OPU_1152   ),
        .s_cnt_raddr_rec_eqsend_with_vld(s_cnt_raddr_rec_eqsend),
        .OPU_1152_VLD   (OPU_1152_VLD),
        .OPU_BIT_SEL    (opu_bit_sel),
        .PIC_SIZE       (PIC_SIZE   ),
        .ONE_BANK_FULL      (SRAM2REG_VLD),

        .CTRL_MUX_1152_1(CTRL_MUX_1152_1),//11bit to sel in 1152
        .REG_ARRAY_ROW  (REG_ARRAY_ROW),//8bit sel from reg_array
        .reg_array_full_o(s_reg_array_full)
    );

    reg   r_gen_raddr_temp    ;
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST)begin
            r_gen_raddr_temp    <= 'b0  ;
        end else begin
            if (s_cnt_raddr_rec_eqsend) begin
                r_gen_raddr_temp    <= 1'b1     ;
            end else if (r_gen_raddr_temp & (~s_reg_array_full))begin
                r_gen_raddr_temp    <= 'b0      ;
            end
        end
    end
    assign s_gen_addr = r_gen_raddr_temp & (~s_reg_array_full)   ;

   
    
    
endmodule