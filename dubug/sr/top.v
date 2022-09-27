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
`include "define.v"
module top #(
    parameter   AW  = 10,
    parameter   DW  = 128
) (
    input   SYS_CLK                 ,
    input   SYS_NRST                ,

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
    output  [7    :0]   REG_ARRAY_ROW   ,//8bit sel from reg_array
    output  [3    :0]   SRAM_STATUS

);
    //===========================================
    // description: input preprocess
    wire    [DW-1 : 0]  s_data          ;
    wire                s_data_vld      ;
    
    wire                s_data_hsync    ;
    wire                s_data_sop      ;
    wire    [AW-1 : 0]  s_wraddr_start  ;
    wire                s_opu_1152_rdy  ;
    wire                s_padding       ;
    wire                s_sram2reg_vld  ;
    wire    [5    : 0]  s_pic_size      ;
    wire    [3    : 0]  s_mode          ;

    assign  s_data          = DATA          ;
    assign  s_data_vld      = DATA_VLD      ;
    assign  s_data_hsync    = DATA_HSYNC    ;
    assign  s_data_sop      = DATA_SOP      ;
    assign  s_wraddr_start  = WRADDR_START  ;
    assign  s_opu_1152_rdy  = OPU_1152_RDY  ;
    assign  s_padding       = PADDING       ;
    assign  s_sram2reg_vld  = SRAM2REG_VLD  ;
    assign  s_pic_size      = PIC_SIZE      ;
    assign  s_mode          = MODE          ;


    //===========================================
    // description: output preprocess
    reg             r_opu_1152_vld          ;
    wire            s_opu_1152_vld          ;
    wire            s_opu_1152_rdy_fake     ;

    reg             r_wready                ;//sram ready for write
    reg             r_sram2reg_rdy          ;//sram ready for pass to reg_array

    assign WREADY       = r_wready          ;
    assign SRAM2REG_RDY = r_sram2reg_rdy    ;
    assign OPU_1152_VLD = s_opu_1152_vld    ;  

    reg    [7   :0] r_cnt_regout_matrix     ;
    wire            s_line_update           ;
    wire            s_regout_matrix         ;


    always @(posedge SYS_CLK or negedge SYS_NRST) begin//for in mode[2] ,line update to refresh 16 period of opu_rdy&vld
        if (!SYS_NRST)begin
            r_cnt_regout_matrix <= 'b0 ;
        end else begin
            if (s_line_update)begin
                r_cnt_regout_matrix    <= 'b0  ;
            end else if (s_regout_matrix)begin
                r_cnt_regout_matrix <= r_cnt_regout_matrix + 1'b1 ;
            end
        end
    end
    assign s_line_update = s_regout_matrix & (r_cnt_regout_matrix == (s_pic_size + (s_padding<<1) - 4'd3) - 1'b1);


    reg     [3   : 0]   r_cnt_opu_rdy   ;
    wire                s_regarray_out  ;

    assign s_regarray_out = r_opu_1152_vld & (s_opu_1152_rdy || s_opu_1152_rdy_fake) ;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_opu_rdy   <= 'b0  ;
        end else begin
            if (s_line_update)begin
                r_cnt_opu_rdy   <= 'b0  ;
            end else if (s_regarray_out) begin
                r_cnt_opu_rdy   <= r_cnt_opu_rdy + 1'b1 ;
            end
        end
    end
    assign s_opu_1152_rdy_fake = s_mode[2] ? (r_cnt_opu_rdy > 4'd7) : 1'b0 ;
    assign s_opu_1152_vld   = r_opu_1152_vld & (~s_opu_1152_rdy_fake)        ;
    

    
    
    reg [1151 : 0]reg_array[7:0]    ;//reg array
    reg [7    : 0]r_cnt_hsync       ;//count data_hsync

    wire [AW+1 :0]s_waddr           ;//write to sram
    wire [AW+1 :0]s_raddr           ;//read from sram

    wire          s_rec_rdata       ;
    wire [2    :0]s_ctrl_regbit_sel ; 

    reg           s_sram2reg_rdy_up ;
    wire          s_sram2reg_rdy_dw ;

    wire [3    :0]s_num_raddr       ;//eq 9/3

    wire [3    :0]s_ctrl_regnum_sel ;//which reg

    reg  [DW-1 :0]s_rdata           ;//read out from sram

    wire          s_reg_array_full  ;

    wire          s_rdata_vld       ;
    wire [3    :0]s_sram_status     ;
    wire          s_reg_array_empty ;

    assign SRAM_STATUS = s_sram_status  ;
    


   
// //======================================================================================
// description: now is for generate ready signal, one for sram2reg ,one for data write to sram
// //======================================================================================
    
    //===========================================
    // description: count hsync signal
    wire s_w2line_hsync             ;//write 1 line done for 
    wire s_w2bank_done              ;//cnt_hsync == 3
    reg  r_w1bank_done              ;//cnt_hsync > 3 & cnt_hsync==2line
    wire s_wdata_done               ;//cnt_hsync == N + padding

    always @(posedge SYS_CLK or negedge SYS_NRST) begin//count hsync data to sram, include the padding situation 
        if (!SYS_NRST) begin
            r_cnt_hsync <= 'b0;
        end else begin
            if (s_data_sop)        r_cnt_hsync <= {7'b0 , s_padding}    ;
            else if (s_data_hsync) r_cnt_hsync <= r_cnt_hsync + 1'b1  ;
        end
    end

    assign s_w2line_hsync = r_cnt_hsync[0] & s_data_hsync       ;//bank write change 
    
    assign s_w2bank_done = (r_cnt_hsync == 8'd4)  ;//write 4 line including padding done

    
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_w1bank_done   <= 'b0  ;
        end else begin
            if (((r_cnt_hsync[0]==1'b1)&s_data_hsync)||s_wdata_done) begin//add s_wdata_done to include the last line in padding
                r_w1bank_done   <= 1'b1 ;
            end else if (s_sram2reg_vld & r_sram2reg_rdy) begin
                r_w1bank_done   <= 1'b0 ;
            end
        end
    end

   
    reg [15:0]   r_cnt_wdata ;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin//count data to sram
        if (!SYS_NRST)begin
            r_cnt_wdata     <= 'b0  ;
        end else begin
            if (s_data_sop)begin
                r_cnt_wdata <= 'b0  ;
            end else if (s_data_vld & r_wready)begin
                r_cnt_wdata <= r_cnt_wdata + 1'b1   ;
            end
        end
    end
    assign s_wdata_done = s_mode[3] ? (r_cnt_wdata == s_pic_size << 3 ) : (r_cnt_wdata == (s_pic_size*s_pic_size)<<3) ;



    //===========================================
    // description: wready signal
    //******(write bank 0 1 )**** **********(write bank 2)***********           *******(write bank 1)********
    //                            ************(read bank 0 1 to register)****** ********(read bank 2 to register)*****
    wire            s_wready_up         ;
    reg             s_wready_dw         ;//for wready
    wire            s_gen_raddr_end     ;
    reg             r_gen_raddr_done    ;
    assign  s_wready_up =  (s_sram2reg_vld & r_sram2reg_rdy) || (s_data_sop)  ;//add condition s_reg_array_empty for in the same with wen change
    
    always @(*) begin
        if (s_sram_status == 4'b0010)begin//in sram write status, when 4 hsync ,wready down
            s_wready_dw = s_w2bank_done ;
        end else if (s_sram_status == 4'b1000)begin//in sram write&read status ,when 2 hsync ,wready down
            s_wready_dw = s_w2line_hsync;
        end else begin//one picture write down
            s_wready_dw = s_wdata_done  ;
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_wready    <= 1'b0 ; 
        end else begin
            if (s_wready_up) begin
                r_wready    <= 1'b1 ;
            end else if (s_wready_dw) begin
                r_wready    <= 1'b0 ;
            end
        end
    end
 
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_gen_raddr_done    <= 'b0  ;
        end else begin
            if (s_gen_raddr_end)begin
                r_gen_raddr_done    <= 1'b1  ;
            end else if (s_sram2reg_vld&r_sram2reg_rdy)begin
                r_gen_raddr_done    <= 1'b0  ;
            end
        end
    end

    //===========================================
    // description: ram2reg_rdy signal
    always @(*) begin
        if (s_sram_status == 4'b0010)begin//sram in write state
            if (s_mode[3])begin
                s_sram2reg_rdy_up = s_wdata_done & s_reg_array_empty   ;
            end else begin
                s_sram2reg_rdy_up = s_w2bank_done & s_reg_array_empty  ; 
            end
             
        end else if (s_sram_status == 4'b1000)begin//sram in write&read state
            s_sram2reg_rdy_up = r_w1bank_done & r_gen_raddr_done & s_reg_array_empty   ;

        end  else begin
            s_sram2reg_rdy_up = 'b0 ;
        end
    end

    assign s_sram2reg_rdy_dw    = s_sram2reg_vld & SRAM2REG_RDY               ;


    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_sram2reg_rdy  <= 'b0  ;
        end else begin
            if (s_sram2reg_rdy_dw)      r_sram2reg_rdy <= 1'b0  ;
            else if (s_sram2reg_rdy_up) r_sram2reg_rdy <= 1'b1  ;
        end
    end

// //======================================================================================
// description: now is for generate waddr to sram
// //======================================================================================

    gen_waddr U_gen_waddr (
        .SYS_CLK                (SYS_CLK        ),
        .SYS_NRST               (SYS_NRST       ),

        .data_sop_i             (s_data_sop     ),
        .data_vld_i             (s_data_vld     ),
        .wready_i               (r_wready       ),
        .wraddr_start_i         (s_wraddr_start ),

        .pic_size_i             (s_pic_size     ),
        .padding_i              (s_padding      ),
        .mode_i                 (s_mode         ),
        .wbank_update_i         (s_w2line_hsync ),//write bank change
        
        .waddr_o                (s_waddr        )   
    );
// //======================================================================================
// description: now is for generate raddr to read from sram
// //======================================================================================

    gen_raddr U_gen_raddr (
        .SYS_CLK            (SYS_CLK        ),
        .SYS_NRST           (SYS_NRST       ),

        .data_sop_i         (s_data_sop     ),

        .gen_raddr_start_i  (s_sram2reg_vld ),//in cnn s_mode or full_connected s_mode
        .gen_raddr_end_o    (s_gen_raddr_end),

        .reg2sram_rec_done_i(s_rec_rdata    ),
        .reg_array_full_i   (s_reg_array_full),

        .mode_i             (s_mode         ),////[0]three direction s_mode ,[1]line s_mode stride=1 , [2]line s_mode stride=2 , [3]full-connected 
        .pic_size_i         (s_pic_size     ),
        .padding_i          (s_padding      ),
        .wraddr_start_i     (s_wraddr_start ),

        .raddr_o            (s_raddr        ),
        .raddr_vld_o        (s_raddr_vld    ),
        .reg_rst_o          (s_raddr_rst    ),
        .num_rdata_o        (s_num_raddr    ),
        
        .ctrl_regnum_sel_o  (s_ctrl_regnum_sel),//gen_mux_1_9_ctrl 
        .ctrl_regbit_sel_o  (s_ctrl_regbit_sel)
        

    );
//======================================================================================
// description: now is for sram,
// //======================================================================================
        wire    [DW-1 :0]   DIN0    ;
        wire    [DW-1 :0]   DIN1    ;
        wire    [DW-1 :0]   DIN2    ;
        wire    [DW-1 :0]   DOUT0   ;
        wire    [DW-1 :0]   DOUT1   ;
        wire    [DW-1 :0]   DOUT2   ;
        wire    [AW-1 :0]   A0      ;
        wire    [AW-1 :0]   A1      ;
        wire    [AW-1 :0]   A2      ;
        wire    [2    :0]   CEN     ;     
        wire    [2    :0]   WEN     ;               

    sram U_sram (
        .SYS_CLK            (SYS_CLK    ),
        .SYS_NRST           (SYS_NRST   ),
        .CEN                (CEN        ),
        .WEN                (WEN        ),
        .A0                 (A0         ),
        .A1                 (A1         ),
        .A2                 (A2         ),

        .DIN0               (DIN0       ),
        .DIN1               (DIN1       ),
        .DIN2               (DIN2       ),
        .DOUT0              (DOUT0      ),
        .DOUT1              (DOUT1      ),
        .DOUT2              (DOUT2      )
    );
//======================================================================================
// description: now is for sram in or out
// //======================================================================================
    

    
    
    gen_sram_interface U_gen_sram_interface (
        .SYS_CLK            (SYS_CLK    ),
        .SYS_NRST           (SYS_NRST   ),

        .mode_i             (s_mode     ),
        .pic_size_i         (s_pic_size ),
        .padding_i          (s_padding  ),

        .wrsram_start_i     (s_sram2reg_vld&r_sram2reg_rdy),
        .wsram_start_i      (s_data_sop ),

        .wdata_i            (s_data     ),
        .wdata_vld_i        (s_data_vld ),
        .waddr_i            (s_waddr    ), 

        .raddr_i            (s_raddr    ),
        .raddr_vld_i        (s_raddr_vld),

        .rsram_done_i       (r_gen_raddr_done),

        .wsram_2line        (s_w2line_hsync ),
        
        .sram_status_o      (s_sram_status  ),
        .CEN_o              (CEN            ),
        .WEN_o              (WEN            ),
        .A0_o               (A0             ),
        .A1_o               (A1             ),
        .A2_o               (A2             ),
        .DIN0_o             (DIN0           ),
        .DIN1_o             (DIN1           ),
        .DIN2_o             (DIN2           )      
    );
    reg [1:0]   rbank_sel  ;
    always @(posedge SYS_CLK or negedge SYS_NRST ) begin
        if (!SYS_NRST) begin
            rbank_sel <= 'b0    ;
        end else begin
            rbank_sel <= s_raddr[11:10]   ;
        end
        
    end
    always @(*) begin
        case (rbank_sel) 

        2'b00 : s_rdata = DOUT0    ;
        2'b01 : s_rdata = DOUT1    ;
        2'b10 : s_rdata = DOUT2    ;
        default : s_rdata = 'b0    ;

        endcase
    end
//======================================================================================
// description: now is for register fifo in or out
// //======================================================================================
    wire [3 :0] s_rdata_regnum  ;
    sync_reg U_sync_reg (
        .SYS_CLK            (SYS_CLK        ),
        .SYS_NRST           (SYS_NRST       ),

        .raddr_rst_i        (s_raddr_rst    ),
        .raddr_vld_i        (s_raddr_vld    ),
        .ctrl_regnum_sel_i  (s_ctrl_regnum_sel),

        .rdata_rst_o        (s_rdata_rst    ),
        .rdata_vld_o        (s_rdata_vld    ),
        .rdata_regnum_o     (s_rdata_regnum )
    );

//===========================================
// description: reg array fifo s_ctrl_regnum_sel ,s_raddr_rst
    reg_array_fifo_ctrl U_reg_array_fifo_ctrl (
        .SYS_CLK            (SYS_CLK        ),
        .SYS_NRST           (SYS_NRST       ),

        .RDATA_VLD          (s_rdata_vld    ),
        .num_rdata_i        (s_num_raddr    ),

        .OPU_1152_RDY       (s_regarray_out ),//input for opu compute ok

        .rec_rdata          (s_rec_rdata    ),

        .reg_array_full     (s_reg_array_full),
        .reg_array_empty    (s_reg_array_empty)
    );

    always @(posedge SYS_CLK or negedge SYS_NRST) begin//when opu rdy up ,opu vld down immidaitely
        if (!SYS_NRST)begin
            r_opu_1152_vld  <= 'b0  ;
        end else begin
            if (s_regarray_out)begin
                r_opu_1152_vld <= 'b0   ;
            end else if(~s_reg_array_empty)begin
                r_opu_1152_vld <= 1'b1  ;
            end
        end
    end
//===========================================
// description: sram readout data to reg_array
    
      always @(posedge SYS_CLK or negedge SYS_NRST) begin//write data to fifo 
        if (!SYS_NRST) begin
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
                reg_array[s_ctrl_regbit_sel][(4'd9-s_rdata_regnum)*DW - 1 -:DW] <= 'b0    ;
           //     $display("RST is put to reg%d bit%d" ,s_ctrl_regnum_sel_d1,s_ctrl_regbit_sel);
            end else if (s_rdata_vld & (~s_reg_array_full) & (~s_rdata_rst)) begin
                reg_array[s_ctrl_regbit_sel][(4'd9-s_rdata_regnum)*DW - 1 -:DW] <= s_rdata  ;
           //     $display("%d is put to reg%d bit%d",s_rdata[0] ,s_ctrl_regnum_sel_d1,s_ctrl_regbit_sel);
            end
        end
        
    end 

//===========================================
// description: reg_array to opu ,mux 6 sel 1 & mux_ctrl
    wire  [2      : 0]  s_ctrl_mux_6_1  ;
    wire  [DW*9-1 : 0]  s_reg_array_bit ;
    mux_ctrl_6_1 U_mux_ctrl_6_1 (
        .SYS_CLK        (SYS_CLK    ),
        .SYS_NRST       (SYS_NRST   ),
        .mode_i         (s_mode     ),
        .ctrl_update_i  (s_regout_matrix),
        .ctrl_reset_i   (r_gen_raddr_done & s_reg_array_empty),//when update line ,ctrl mux6_1 should be reset
        .pic_size       (s_pic_size ),//for speicla mode1
        .padding        (s_padding  ),

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

    wire  [2:0]     s_ctrl_mux_8_1   ;

    mux_ctrl_8_1 U_mux_ctrl_8_1 (
        .SYS_CLK            (SYS_CLK        ),
        .SYS_NRST           (SYS_NRST       ),

        .reg_out_i          (s_regarray_out ),
        .ctrl_mux_8_1_o     (s_ctrl_mux_8_1 ),
        .regout_matrix_o    (s_regout_matrix)
    );

    mux_8_1 U_mux_8_1 (
        .REG_ARRAY_BIT0     ( reg_array[0]   ),
        .REG_ARRAY_BIT1     ( reg_array[1]   ),
        .REG_ARRAY_BIT2     ( reg_array[2]   ),
        .REG_ARRAY_BIT3     ( reg_array[3]   ),
        .REG_ARRAY_BIT4     ( reg_array[4]   ),
        .REG_ARRAY_BIT5     ( reg_array[5]   ),
        .REG_ARRAY_BIT6     ( reg_array[6]   ),
        .REG_ARRAY_BIT7     ( reg_array[7]   ),

        .CTRL_MUX_8_1       (s_ctrl_mux_8_1  ),

        .REG_ARRAY_1152     (s_reg_array_bit )
    );

//===========================================
// description: mux_1152_1 for weight check
    assign REG_ARRAY_ROW = (CTRL_MUX_1152_1 < DW*9 ) ? {reg_array[7][CTRL_MUX_1152_1] , reg_array[6][CTRL_MUX_1152_1] ,reg_array[5][CTRL_MUX_1152_1] 
                                                       ,reg_array[4][CTRL_MUX_1152_1] , reg_array[3][CTRL_MUX_1152_1] ,reg_array[2][CTRL_MUX_1152_1]
                                                       ,reg_array[1][CTRL_MUX_1152_1] , reg_array[0][CTRL_MUX_1152_1] } : 'b0   ;

  
    
    
endmodule