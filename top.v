// +FHEADER ==================================================
// FilePath       : \sr\top.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-29 18:20:06
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-19 23:30:38
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
`define sim_top 1

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
    //===========================================
    // description: input preprocess
    wire    [DW-1 : 0]  s_data      ;
    wire                s_data_vld  ;
    
    wire                s_data_hsync    ;
    wire                s_data_sop      ;
    wire    [AW-1 : 0]  s_wraddr_start  ;
    wire                s_opu_1152_rdy  ;
    wire                s_padding       ;
    wire                s_sram2reg_vld  ;
    wire    [7    : 0]  s_pic_size      ;
    wire    [3    : 0]  s_mode          ;

    assign  s_data      = DATA          ;
    assign  s_data_vld  = DATA_VLD      ;
    assign  s_data_hsync= DATA_HSYNC    ;
    assign  s_data_sop  = DATA_SOP      ;
    assign  s_wraddr_start  = WRADDR_START  ;
    assign  s_opu_1152_rdy  = OPU_1152_RDY  ;
    assign  s_padding       = PADDING       ;
    assign  s_sram2reg_vld  = SRAM2REG_VLD  ;
    assign  s_pic_size      = PIC_SIZE      ;
    assign  s_mode          = MODE          ;


    //===========================================
    // description: output preprocess
    reg             r_opu_1152_vld  ;

    reg             r_wready        ;//sram ready for write
    reg             r_sram2reg_rdy  ;//sram ready for pass to reg_array

    assign WREADY       = r_wready  ;
    assign SRAM2REG_RDY = r_sram2reg_rdy  ;
    assign OPU_1152_VLD = r_opu_1152_vld  ;  
        
    
    
    reg [1151 : 0]reg_array[7:0]    ;//reg array
    reg [7    : 0]r_cnt_hsync       ;//count data_hsync

  //  reg [AW+1 : 0]r_waddr           ;
    wire [AW+1 :0]s_waddr           ;//write to sram
    wire [AW+1 :0]s_raddr           ;//read from sram
   // reg           r_raddr_vld       ;
   // reg           r_raddr_rst       ;//rst register
   wire           s_rec_rdata       ;
   wire  [2    :0]s_ctrl_regbit_sel   ; 

    
    wire            s_wready_up     ;
    wire            s_wready_dw     ;//for wready
    wire            s_r2bank_done   ;//read 2 bank to reg_array

    
    reg  [1:0]      r_sram2reg_rdy_temp ;
    wire            s_sram2reg_rdy_up   ;
    wire            s_sram2reg_rdy_dw   ;
//    wire            s_w1bank_full   ;//write 1 bank full 

    

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
    wire        s_reg_array_empty   ;

    assign SRAM_STATUS = s_sram_status  ;
    


   
// //======================================================================================
// description: now is for generate ready signal, one for sram2reg ,one for data write to sram
// //======================================================================================
    
    //===========================================
    // description: count hsync signal
    wire s_cnt_hsync_eq_2line       ;
    wire s_two_bank_full            ;//cnt_hsync == 3
    wire s_one_bank_full            ;//cnt_hsync > 3 & cnt_hsync==2line
    wire s_cnt_hsync_eq_N           ;//cnt_hsync == N + padding

    always @(posedge SYS_CLK or negedge SYS_RST) begin//count hsync data to sram, include the padding situation 
        if (!SYS_RST) begin
            r_cnt_hsync <= 'b0;
        end else begin
            if (s_data_sop)        r_cnt_hsync <= {7'b0 , s_padding}    ;
            else if (s_data_hsync) r_cnt_hsync <= r_cnt_hsync + 1'b1  ;
        end
    end

    assign s_cnt_hsync_eq_2line = r_cnt_hsync[0] & s_data_hsync       ;//bank write change 
    
    assign s_two_bank_full = (r_cnt_hsync == 8'd3) & s_data_hsync          ;
    assign s_one_bank_full = (r_cnt_hsync > 8'd3) & s_cnt_hsync_eq_2line ;

    assign s_cnt_hsync_eq_N = (r_cnt_hsync == s_pic_size -1 + s_padding) & s_data_hsync  ;


    //===========================================
    // description: wready signal
    //******(write bank 0 1 )**** **********(write bank 2)***********           *******(write bank 1)********
    //                            ************(read bank 0 1 to register)****** ********(read bank 2 to register)*****
    assign  s_wready_up =   ((&r_sram2reg_rdy_temp)&s_reg_array_empty) || (s_data_sop)  ;//add condition s_reg_array_empty for in the same with wen change
    assign  s_wready_dw =   s_one_bank_full || s_cnt_hsync_eq_N ;//one_bank_full is write 2 line to sram ok,add cnt_hsync_eq_N, for when input over,wready down
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_wready    <= 1'b0 ; 
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
    reg [7 : 0]r_cnt_r2bank_done    ;
    wire       s_rbank2idle         ;   

    assign s_sram2reg_rdy_up    = (s_sram_status==4'b1000) ? ((&r_sram2reg_rdy_temp)&s_reg_array_empty) : (s_reg_array_empty&(r_sram2reg_rdy_temp[1]&(r_cnt_r2bank_done < ((s_pic_size>>1)+s_padding-1'b1))))  ;//add the condition of reg array is empty              
    assign s_sram2reg_rdy_dw    = s_sram2reg_vld & SRAM2REG_RDY               ;
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_sram2reg_rdy_temp = 'b0   ;
        end else begin
            if (s_sram2reg_rdy_up)  r_sram2reg_rdy_temp    = 0  ;//down immediately
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

// //======================================================================================
// description: now is for generate waddr to sram
// //======================================================================================

    gen_waddr U_gen_waddr (
        .SYS_CLK            (SYS_CLK    ),
        .SYS_RST            (SYS_RST    ),
        .DATA_SOP           (s_data_sop   ),
        .DATA_VLD           (s_data_vld   ),
        .WREADY             (r_wready   ),
        .WRADDR_START       (s_wraddr_start),

        .PIC_SIZE           (s_pic_size   ),
        .PADDING            (s_padding    ),
        .MODE               (s_mode       ),
        .WBANK_UPDATE       (s_cnt_hsync_eq_2line),//write bank change
        
        .WADDR              (s_waddr    )   
    );
// //======================================================================================
// description: now is for generate raddr to read from sram
// //======================================================================================

    gen_raddr U_gen_raddr (
        .SYS_CLK            (SYS_CLK    ),
        .SYS_RST            (SYS_RST    ),
        .gen_raddr_hsync_i  (s_sram2reg_vld),
        .gen_raddr_sop_i    (s_two_bank_full),
        .rec_rdata_i          (s_rec_rdata),

        .mode_i             (s_mode),////[0]three direction mode ,[1]line mode stride=1 , [2]line mode stride=2 , [3]full-connected 
        .DATA_EOP           (DATA_EOP),
        .pic_size_i         (s_pic_size),
        .WADDR              (s_waddr),
        .padding_i          (s_padding),
      //  .gen_raddr_bit_i    (s_ctrl_bit_sel),
        .wraddr_start_i     (s_wraddr_start),

        .reg_array_full_i   (s_reg_array_full),

        .raddr_o            (s_raddr),
        .raddr_vld_o        (s_raddr_vld),
        .reg_rst_o          (s_raddr_rst),
        .num_rdata_o        (s_num_raddr ),
        
        .ctrl_regnum_sel_o  (s_ctrl_regnum_sel),//gen_mux_1_9_ctrl 
        .ctrl_regbit_sel_o  (s_ctrl_regbit_sel),
        .r2bank_done_o      (s_r2bank_done)

    );

//======================================================================================
// description: now is for sram in or out
// //======================================================================================
    
    always @(posedge SYS_CLK or negedge SYS_RST) begin//generate signal for sram state from read sram to idle sram
        if (!SYS_RST)begin
            r_cnt_r2bank_done   <= 'b0  ;
        end else begin
            if (s_data_sop)begin
                r_cnt_r2bank_done   <= 'b0  ;
            end else if(s_r2bank_done)begin
                r_cnt_r2bank_done   <= r_cnt_r2bank_done + 1'b1     ;
            end
        end
    end
    assign s_rbank2idle  = ((r_cnt_r2bank_done == ((s_pic_size>>1)+s_padding-1'b1-1'b1)) ? 1'b1 : 1'b0 )&s_r2bank_done  ;
    
    gen_sram_interface U_gen_sram_interface (
        .SYS_CLK        (SYS_CLK),
        .SYS_RST        (SYS_RST),
        .mode_i           (s_mode),
        .r2wrsram_i  (s_two_bank_full),
        .wrsram_bank_change_i  (s_sram2reg_vld),
        .data_sop_i       (s_data_sop),
        .DATA_EOP       (DATA_EOP),
        .wdata_i           (s_data),
        .wdata_vld_i       (s_data_vld),
  //      .PIC_SIZE       (PIC_SIZE),

        .raddr_i          (s_raddr),
        .raddr_vld_i      (s_raddr_vld),
        .waddr_i          (s_waddr), 
        .r2bank_done_i    (s_r2bank_done),
        .wr2rsram_i       (s_cnt_hsync_eq_N),
        .wsram_2line      (s_cnt_hsync_eq_2line),
        .rsram2idle_i     (s_rbank2idle),

        .rdata_o              (s_rdata),
        .rdata_vld_o      (s_rdata_vld),
        .sram_status_o   (s_sram_status)
    );

//======================================================================================
// description: now is for register fifo in or out
// //======================================================================================
    //delay one clock for 

//===========================================
// description: reg array fifo s_ctrl_regnum_sel ,s_raddr_rst
    wire [3:0]s_ctrl_regnum_sel_d1   ;
    wire s_rdata_rst            ;
    reg  [3:0]r_ctrl_regnum_sel_d1   ;
    reg  r_rdata_rst            ;
    assign s_ctrl_regnum_sel_d1 = r_ctrl_regnum_sel_d1  ;
    assign s_rdata_rst          = r_rdata_rst           ;
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_ctrl_regnum_sel_d1    <= 'b0  ;
            r_rdata_rst             <= 'b0  ;
        end else begin
            r_ctrl_regnum_sel_d1    <= s_ctrl_regnum_sel    ;
            r_rdata_rst             <= s_raddr_rst          ;
        end
    end

    reg_array_fifo_ctrl U_reg_array_fifo_ctrl (
        .SYS_CLK        (SYS_CLK),
        .SYS_RST        (SYS_RST),

        .RDATA_VLD      (s_rdata_vld),
        .num_rdata_i    (s_num_raddr),

        .OPU_1152_RDY   (s_opu_1152_rdy),//input for opu compute ok

        .rec_rdata      (s_rec_rdata),

        .reg_array_full (s_reg_array_full),
        .reg_array_empty(s_reg_array_empty)
    );

    always @(posedge SYS_CLK or negedge SYS_RST) begin//when opu rdy up ,opu vld down immidaitely
        if (!SYS_RST)begin
            r_opu_1152_vld  <= 'b0  ;
        end else begin
            if (r_opu_1152_vld & s_opu_1152_rdy)begin
                r_opu_1152_vld <= 'b0   ;
            end else if(~s_reg_array_empty)begin
                r_opu_1152_vld <= 1'b1  ;
            end
        end
    end
//===========================================
// description: sram readout data to reg_array
    
      always @(posedge SYS_CLK or negedge SYS_RST) begin//write data to fifo 
        if (!SYS_RST) begin
            reg_array[0]    <= 'b0  ;
            reg_array[1]    <= 'b0  ;
            reg_array[2]    <= 'b0  ;
            reg_array[3]    <= 'b0  ;
            reg_array[4]    <= 'b0  ;
            reg_array[5]    <= 'b0  ;
            reg_array[6]    <= 'b0  ;
            reg_array[7]    <= 'b0  ;
        end else begin
            if (s_rdata_vld & (~s_reg_array_full) & s_rdata_rst) begin//rst reg first ,and then data to reg
                reg_array[s_ctrl_regbit_sel][(4'd9-s_ctrl_regnum_sel_d1)*DW - 1 -:DW] <= 'b0    ;
           //     $display("RST is put to reg%d bit%d" ,s_ctrl_regnum_sel_d1,s_ctrl_regbit_sel);
            end else if (s_rdata_vld & (~s_reg_array_full) & (~s_rdata_rst)) begin
                reg_array[s_ctrl_regbit_sel][(4'd9-s_ctrl_regnum_sel_d1)*DW - 1 -:DW] <= s_rdata  ;
           //     $display("%d is put to reg%d bit%d",s_rdata[0] ,s_ctrl_regnum_sel_d1,s_ctrl_regbit_sel);
            end
        end
        
    end

//===========================================
// description: count the number of opu_vld&opu_rdy, for mux out ctrl
    reg     [2      :0] r_reg2opu_ctrl_bit      ;
    wire                s_reg2opu_ctrl_bit_eq7  ;

    wire    [DW*9-1 :0] s_reg_array_bit         ;
  //  wire    [DW*9-1 :0] OPU_1152                ;
   // reg     [DW*9-1 :0] reg_array[7:0]          ;//reg_array


    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_reg2opu_ctrl_bit  <= 'b0  ;
        end else begin
            if (s_opu_1152_rdy & r_opu_1152_vld) begin
                r_reg2opu_ctrl_bit  <= r_reg2opu_ctrl_bit + 1   ;
            end
        end
    end
    assign s_reg2opu_ctrl_bit_eq7 = s_opu_1152_rdy & r_opu_1152_vld & (r_reg2opu_ctrl_bit == 7) ;


//===========================================
// description: reg_array to opu ,mux 6 sel 1 & mux_ctrl
    wire  [2:0]   s_ctrl_mux_6_1  ;

    mux_ctrl_6_1 U_mux_ctrl_6_1 (
        .SYS_CLK        (SYS_CLK),
        .SYS_RST        (SYS_RST),
        .mode_i         (s_mode)   ,
        .ctrl_update_i  (s_reg2opu_ctrl_bit_eq7),
        .ctrl_reset_i   (s_sram2reg_rdy_dw),//when update line ,ctrl mux6_1 should be reset

        .ctrl_mux_6_1   (s_ctrl_mux_6_1)
    );

    mux_6_1 U_mux_6_1 (
        .CTRL_MUX_6_1       (s_ctrl_mux_6_1         ),
        .REG_ARRAY_1152     (s_reg_array_bit        ),

        .MUX2OPU_0          (OPU_1152[DW*9-1 -:DW]  ),
        .MUX2OPU_1          (OPU_1152[DW*8-1 -:DW]  ),
        .MUX2OPU_2          (OPU_1152[DW*7-1 -:DW]  ),
        .MUX2OPU_3          (OPU_1152[DW*6-1 -:DW]  ),
        .MUX2OPU_4          (OPU_1152[DW*5-1 -:DW]  ),
        .MUX2OPU_5          (OPU_1152[DW*4-1 -:DW]  ),
        .MUX2OPU_6          (OPU_1152[DW*3-1 -:DW]  ),
        .MUX2OPU_7          (OPU_1152[DW*2-1 -:DW]  ),
        .MUX2OPU_8          (OPU_1152[DW*1-1 -:DW]  )
    );
//===========================================
    // description: reg_array to opu ,mux 8 sel 1
`ifdef sim_top
    wire  [DW*9-1 :0] reg_array0     ;
    wire  [DW*9-1 :0] reg_array1     ; 
    wire  [DW*9-1 :0] reg_array2     ; 
    wire  [DW*9-1 :0] reg_array3     ;  
    wire  [DW*9-1 :0] reg_array4     ; 
    wire  [DW*9-1 :0] reg_array5     ; 
    wire  [DW*9-1 :0] reg_array6     ; 
    wire  [DW*9-1 :0] reg_array7     ; 

    assign reg_array0 = reg_array[0]    ;
    assign reg_array1 = reg_array[1]    ;
    assign reg_array2 = reg_array[2]    ;
    assign reg_array3 = reg_array[3]    ;
    assign reg_array4 = reg_array[4]    ;
    assign reg_array5 = reg_array[5]    ;
    assign reg_array6 = reg_array[6]    ;
    assign reg_array7 = reg_array[7]    ;
    
`endif 
    mux_8_1 U_mux_8_1 (
        .REG_ARRAY_BIT0     ( reg_array[0]   ),
        .REG_ARRAY_BIT1     ( reg_array[1]   ),
        .REG_ARRAY_BIT2     ( reg_array[2]   ),
        .REG_ARRAY_BIT3     ( reg_array[3]   ),
        .REG_ARRAY_BIT4     ( reg_array[4]   ),
        .REG_ARRAY_BIT5     ( reg_array[5]   ),
        .REG_ARRAY_BIT6     ( reg_array[6]   ),
        .REG_ARRAY_BIT7     ( reg_array[7]   ),

        .CTRL_MUX_8_1       (r_reg2opu_ctrl_bit ),

        .REG_ARRAY_1152     (s_reg_array_bit    )
    );

//===========================================
// description: mux_1152_1 for weight check
    assign REG_ARRAY_ROW = (CTRL_MUX_1152_1 < DW*9 ) ? {reg_array[7][CTRL_MUX_1152_1] , reg_array[6][CTRL_MUX_1152_1] ,reg_array[5][CTRL_MUX_1152_1] 
                                                       ,reg_array[4][CTRL_MUX_1152_1] , reg_array[3][CTRL_MUX_1152_1] ,reg_array[2][CTRL_MUX_1152_1]
                                                       ,reg_array[1][CTRL_MUX_1152_1] , reg_array[0][CTRL_MUX_1152_1] } : 'b0   ;

  
    
    
endmodule