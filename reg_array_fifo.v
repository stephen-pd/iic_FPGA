module reg_array_fifo #(
    parameter   AW  = 10    ,
    parameter   DW  = 128   
) (
    input   SYS_CLK ,
    input   SYS_RST ,

    input   [DW-1 :0]   RDATA           ,
    input   [2    :0]   CTRL_BIT_SEL    ,
    input   [3    :0]   CTRL_REGNUM_SEL ,//for data to reg_array
    input               RDATA_VLD       ,
    input               REG_RST         ,
    input   [3    :0]   NUM_RADDR       ,
    input   [3    :0]   MODE            ,

    input   [7    :0]   PIC_SIZE        ,
    input               ONE_BANK_FULL   ,

    input               OPU_1152_RDY    ,//input for opu compute ok

    input   [AW   :0]   CTRL_MUX_1152_1 ,//11bit to sel in 1152
    output  [7    :0]   REG_ARRAY_ROW   ,//8bit sel from reg_array

    output  [DW*9-1 :0] OPU_1152        ,
    output              s_cnt_raddr_rec_eqsend_with_vld  ,
    output              OPU_1152_VLD    ,
    output  [2    :0]   OPU_BIT_SEL     ,
    output              reg_array_full_o//the reg fifo is full
);
    
    reg     [2      :0] r_reg2opu_ctrl_bit  ;//mux 8 sel 1

    reg     [3      :0] r_reg2opu_ctrl_type ;//6 type reflect between reg_array and opu

    reg     [2      :0] r_ctrl_mux_6_1      ;//for mux6_1 control

    reg     [DW*9-1 :0] reg_array[7:0]      ;//reg_array
    reg                 r_opu_1152_vld      ;
    wire    [DW*9-1 :0] s_reg_array_bit0    ;
    wire    [DW*9-1 :0] s_reg_array_bit1    ;
    wire    [DW*9-1 :0] s_reg_array_bit2    ;
    wire    [DW*9-1 :0] s_reg_array_bit3    ;
    wire    [DW*9-1 :0] s_reg_array_bit4    ;
    wire    [DW*9-1 :0] s_reg_array_bit5    ;
    wire    [DW*9-1 :0] s_reg_array_bit6    ;
    wire    [DW*9-1 :0] s_reg_array_bit7    ;
    wire    [DW*9-1 :0] s_reg_array_bit     ;

    wire                s_reg2opu_ctrl_bit_eq7  ;

    wire s_full     ;
    wire s_empty    ;//empty or full for fifo

   // wire s_cnt_raddr_rec_eqsend_with_vld    ;
    wire s_cnt_raddr_rec_eqsend             ;           

    reg [3:0]   r_cnt_raddr_rec         ;//count reg_array receive the data
   // wire        s_cnt_raddr_rec_eqsend  ;

    reg [3:0]   rptr                    ;//read point
    reg [3:0]   wptr                    ;//write point

    reg [2:0]   r_opu_bit_sel           ;

    assign reg_array_full_o = s_full    ;
 

    assign OPU_BIT_SEL = r_opu_bit_sel  ;

    assign REG_ARRAY_ROW = (CTRL_MUX_1152_1 < DW*9 ) ? {reg_array[7][CTRL_MUX_1152_1] , reg_array[6][CTRL_MUX_1152_1] ,reg_array[5][CTRL_MUX_1152_1] 
                                                       ,reg_array[4][CTRL_MUX_1152_1] , reg_array[3][CTRL_MUX_1152_1] ,reg_array[2][CTRL_MUX_1152_1]
                                                       ,reg_array[1][CTRL_MUX_1152_1] , reg_array[0][CTRL_MUX_1152_1] } : 'b0   ;

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
            if (RDATA_VLD & (~s_full) & REG_RST) begin//rst reg first ,and then data to reg
                reg_array[CTRL_BIT_SEL][(9-CTRL_REGNUM_SEL)*DW - 1 -:DW] <= 'b0    ;
            end else if (RDATA_VLD & (~s_full) & (~REG_RST)) begin
                reg_array[CTRL_BIT_SEL][(9-CTRL_REGNUM_SEL)*DW - 1 -:DW] <= RDATA  ;
            end
        end
        
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin//read data from fifo
        if (!SYS_RST) begin
            r_opu_bit_sel     <= 'b0  ;
        end else begin
            if ( (~s_empty) & OPU_1152_RDY) begin
                r_opu_bit_sel <= r_opu_bit_sel + 1  ;
            end
        end
    end


    always @(posedge SYS_CLK or negedge SYS_RST) begin//write point
        if (!SYS_RST) begin
            wptr    <= 'b0  ;
        end else begin
            if (s_cnt_raddr_rec_eqsend & (~s_full)) begin
                wptr    <= wptr + 1'b1  ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin//read point
        if (!SYS_RST) begin
            rptr    <= 'b0  ;
        end else begin
            if ( (~s_empty) & OPU_1152_RDY) begin
                rptr    <= rptr + 1'b1  ;
            end
        end
    end
    wire temp   ;
    assign temp =  (~s_empty) & OPU_1152_RDY    ;

    always @(posedge SYS_CLK or negedge SYS_RST) begin//reg_array receive signal
        if (!SYS_RST) begin
            r_cnt_raddr_rec <= 'b0  ;
        end else begin
            if (s_cnt_raddr_rec_eqsend) begin
                r_cnt_raddr_rec <= 'b0  ;
            end else if (RDATA_VLD) begin
                r_cnt_raddr_rec <= r_cnt_raddr_rec + 1'b1    ;
            end
        end
    end

    wire [3:0] s_num_raddr_temp ;
    reg r_cnt_raddr_rec_eqsend_vld ;//vld for ...
    assign s_num_raddr_temp       = (NUM_RADDR == 4'b1010) ? 4'd9  : 4'd3   ;
    assign s_cnt_raddr_rec_eqsend = (r_cnt_raddr_rec == s_num_raddr_temp) ? 1'b1 : 'b0  ;//eq 3 or 9

    reg [7:0] r_cnt_s_cnt_raddr_rec_eqsend  ;
    always @(posedge SYS_CLK or negedge SYS_RST) begin//count the number of received 
        if (!SYS_RST) begin
            r_cnt_s_cnt_raddr_rec_eqsend <= 'b0     ;
        end else begin
            if ( ONE_BANK_FULL )begin
                r_cnt_s_cnt_raddr_rec_eqsend <= 'b0                     ;
            end else if (s_cnt_raddr_rec_eqsend) begin
                r_cnt_s_cnt_raddr_rec_eqsend <= r_cnt_s_cnt_raddr_rec_eqsend + 1'b1     ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin//vld signal generated for 
        if (!SYS_RST) begin
            r_cnt_raddr_rec_eqsend_vld <= 1'b1   ;
        end else begin
            if ((r_cnt_s_cnt_raddr_rec_eqsend == (2*(PIC_SIZE - 2)*8 - 1)) & s_cnt_raddr_rec_eqsend) begin//three cnn mode ,one bank receive 2(N - 2)*8 data,sub 2 is for the last request not send 
                r_cnt_raddr_rec_eqsend_vld <= 'b0   ;
            end else if (ONE_BANK_FULL) begin
                r_cnt_raddr_rec_eqsend_vld <= 1'b1   ;
            end
        end
    end

    assign s_empty = (wptr == rptr) ? 1 : 0                 ;
    assign s_full  = (wptr == {(~rptr[3]),rptr[2:0]}) ? 1 : 0  ;

    
    assign OPU_1152_VLD = r_opu_1152_vld                        ;//wrong because opu_1152_vld should be down when rdy&vld
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST)begin
            r_opu_1152_vld  <= 'b0  ;
        end else begin
            if (OPU_1152_VLD & OPU_1152_RDY)begin
                r_opu_1152_vld <= 'b0   ;
            end else if(~s_empty)begin
                r_opu_1152_vld <= 1'b1  ;
            end
        end
    end


    //===========================================
    // description: reg_array to opu ,mux 6 sel 1
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_reg2opu_ctrl_type     <= 'b0  ;
        end else begin
            if ((r_reg2opu_ctrl_type == 11) & s_reg2opu_ctrl_bit_eq7 & MODE[0]) begin//reflect type loop OF 12 in mode0
                r_reg2opu_ctrl_type <= 'b0  ;
            end else if ((r_reg2opu_ctrl_type == 2) & s_reg2opu_ctrl_bit_eq7 & (MODE[1]||MODE[2]) ) begin//REFLECT type loop of 3 in MODE[1/2] 
                r_reg2opu_ctrl_type <= 'b0  ;
            end else if (s_reg2opu_ctrl_bit_eq7) begin
                r_reg2opu_ctrl_type <= r_reg2opu_ctrl_type + 1  ;
            end
        end
    end

    always @(*) begin
        if (MODE[0]) begin//mode0
            case (r_reg2opu_ctrl_type)

            4'd0 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd1 : r_ctrl_mux_6_1  = 3'd1   ;
            4'd2 : r_ctrl_mux_6_1  = 3'd2   ;
            4'd3 : r_ctrl_mux_6_1  = 3'd3   ;
            4'd4 : r_ctrl_mux_6_1  = 3'd4   ;
            4'd5 : r_ctrl_mux_6_1  = 3'd5   ;
            4'd6 : r_ctrl_mux_6_1  = 3'd1   ;
            4'd7 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd8 : r_ctrl_mux_6_1  = 3'd3   ;
            4'd9 : r_ctrl_mux_6_1  = 3'd2   ;
            4'd10: r_ctrl_mux_6_1  = 3'd5   ;
            4'd11: r_ctrl_mux_6_1  = 3'd4   ;
            default : r_ctrl_mux_6_1  = 3'd0;
            endcase 
        end else if (MODE[1]) begin//mode1
            case (r_reg2opu_ctrl_type)
            
            4'd0 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd1 : r_ctrl_mux_6_1  = 3'd3   ;
            4'd2 : r_ctrl_mux_6_1  = 3'd4   ; 
            default: r_ctrl_mux_6_1  = 3'd0   ;
            endcase
            
        end else if (MODE[2]) begin//mode2
            case (r_reg2opu_ctrl_type)
            
            4'd0 : r_ctrl_mux_6_1  = 3'd0   ;
            4'd1 : r_ctrl_mux_6_1  = 3'd4   ;
            4'd2 : r_ctrl_mux_6_1  = 3'd3   ; 
            default: r_ctrl_mux_6_1  = 3'd0 ;
            endcase
        end else begin
            r_ctrl_mux_6_1  = 3'd0          ;
        end
        
    end
    mux_6_1 U_mux_6_1 (
        .CTRL_MUX_6_1       (r_ctrl_mux_6_1         ),
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
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_reg2opu_ctrl_bit  <= 'b0  ;
        end else begin
            if (OPU_1152_RDY & OPU_1152_VLD) begin
                r_reg2opu_ctrl_bit  <= r_reg2opu_ctrl_bit + 1   ;
            end
        end
    end
    assign s_reg2opu_ctrl_bit_eq7 = OPU_1152_RDY & OPU_1152_VLD & (r_reg2opu_ctrl_bit == 7) ;

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

    assign s_cnt_raddr_rec_eqsend_with_vld = s_cnt_raddr_rec_eqsend & r_cnt_raddr_rec_eqsend_vld;//for output


endmodule