module reg_array_fifo_ctrl(
    input   SYS_CLK ,
    input   SYS_NRST ,

  //  input   [DW-1 :0]   RDATA           ,
  //  input   [2    :0]   CTRL_BIT_SEL    ,
   // input   [3    :0]   CTRL_REGNUM_SEL ,//for data to reg_array
    input               RDATA_VLD       ,
  //  input               REG_RST         ,

    input   [3    :0]   num_rdata_i     ,//9/3
 //   input   [3    :0]   MODE            ,

 //   input   [7    :0]   PIC_SIZE        ,
  //  input               ONE_BANK_FULL   ,

    input               OPU_1152_RDY    ,//input for opu compute ok

    

 //   output  [DW*9-1 :0] OPU_1152        ,
    output              rec_rdata       ,
  //  output              OPU_1152_VLD    ,
  //  output  [2    :0]   OPU_BIT_SEL     ,
    output              reg_array_full  ,
    output              reg_array_empty
);
    
    //mux 8 sel 1

 //   reg     [3      :0] r_reg2opu_ctrl_type ;//6 type reflect between reg_array and opu

 //   reg     [2      :0] r_ctrl_mux_6_1      ;//for mux6_1 control

    
  //  reg                 r_opu_1152_vld      ;

    


    
   // wire        s_cnt_rdata_rec_eqsend  ;
    //===========================================
    // description: input preprocess
    wire [3 : 0]    num_rdata   ;
    assign num_rdata    = num_rdata_i   ;

    //===========================================
    // description: output preprocess
    wire s_full                             ;
    wire s_empty                            ;
    wire s_cnt_rdata_rec_eqsend             ; 

    assign reg_array_full   = s_full    ;
    assign reg_array_empty  = s_empty   ;
    assign rec_rdata        = s_cnt_rdata_rec_eqsend    ;
 

    //===========================================
    // description: fifo rptr and wptr, empty or full
    reg [3:0]   rptr                    ;//read point
    reg [3:0]   wptr                    ;//write point

    always @(posedge SYS_CLK or negedge SYS_NRST) begin//write point
        if (!SYS_NRST) begin
            wptr    <= 'b0  ;
        end else begin
            if (s_cnt_rdata_rec_eqsend & (~s_full)) begin
                wptr    <= wptr + 1'b1  ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin//read point
        if (!SYS_NRST) begin
            rptr    <= 'b0  ;
        end else begin
            if ( (~s_empty) & OPU_1152_RDY) begin
                rptr    <= rptr + 1'b1  ;
            end
        end
    end

    assign s_empty = (wptr == rptr) ? 1 : 0                 ;
    assign s_full  = (wptr == {(~rptr[3]),rptr[2:0]}) ? 1 : 0  ;
    //===========================================
    // description: count the rec data 9 or 3
    reg [3:0]   r_cnt_raddr_rec         ;//count reg_array receive the data

    always @(posedge SYS_CLK or negedge SYS_NRST) begin//reg_array receive signal
        if (!SYS_NRST) begin
            r_cnt_raddr_rec <= 'b0  ;
        end else begin
            if (s_cnt_rdata_rec_eqsend) begin
                r_cnt_raddr_rec <= 'b0  ;
            end else if (RDATA_VLD) begin
                r_cnt_raddr_rec <= r_cnt_raddr_rec + 1'b1    ;
            end
        end
    end
    assign s_cnt_rdata_rec_eqsend = (r_cnt_raddr_rec == num_rdata) ? 1'b1 : 'b0  ;//eq 3 or 9


endmodule