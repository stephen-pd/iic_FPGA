// +FHEADER ==================================================
// FilePath       : \sr\gen_raddr.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-30 10:39:36
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-20 01:55:06
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
//`define sim_gen_raddr 1
module gen_raddr #(
    parameter AW = 10    
) (
    input           SYS_CLK                     ,
    input           SYS_NRST                    ,

    input           data_sop_i                  ,

    input           gen_raddr_start_i           ,//when sram2reg_rdy&vld ,start gen raddr of one line 
    output          gen_raddr_end_o             ,//fsm state is done

    input [3    :0] mode_i                      ,//[0]three direction mode ,[1]line mode stride=1 , [2]line mode stride=2 , [3]full-connected 
    input           padding_i                   ,
    input [AW-1 :0] wraddr_start_i              ,

    input           reg2sram_rec_done_i         ,//regarray receive rdata of 9/3 data
    input [5    :0] pic_size_i                  , 

    input           reg_array_full_i            ,

    output [AW+1:0] raddr_o                     ,//out raddr
    output          raddr_vld_o                 ,
    output          reg_rst_o                   ,
    
    output [3   :0] num_rdata_o                 ,//how many data reg_arry should receive

    output [2   :0] ctrl_regbit_sel_o           ,
    output [3   :0] ctrl_regnum_sel_o            //for ctrl_mux_1_9
    
);
    reg [5:0]r_cnt_matrix       ;//count the read_one_matrix 
    reg [7:0]fsm_rsram_cstate   ;
    reg [7:0]fsm_rsram_nstate   ;

    reg [1:0]r_cnt_raddr_L      ;
    reg [1:0]r_cnt_raddr_H      ;//raddr counter L(low 2 bit),H(high 2 bit)

 //   reg r_raddr_vld         ;//for counter enable

    reg [2:0]r_bank_status      ;//three bank status, 1 is write mode , 0 is read mode
    // reg [7:0]r_cnt_bankloop     ;//the period of bank loop 
    // reg [1:0]s_raddr_M2         ;//raddr hign two bits [11:10]


    reg [1:0]r_x_offset         ;
    reg [1:0]r_y_offset         ;//the x or y offset

    reg [11:0]lut[2:0]          ;//store 0_1_2_3_4_5_6_7_8
    reg [11:0]lut_row           ;//one row of lut
    reg [1:0]lut_x              ;
    reg [1:0]lut_y              ;//lut sel signal
    reg [3:0]lut_out            ;//read out from lut

    reg [3:0]r_lut_out_d1       ;//lut_out delay one clock

    reg     r_raddr_vld         ;//raddr vild
    reg     r_reg_rst           ;//reg array rst
    reg [7 :0]r_cnt_gen_raddr_start ;//count gen_raddr_start

    reg     r_raddr_vld_d1      ;//r_raddr_vld delay one clock
    reg     r_raddr_vld_d2      ;//r_raddr_vld delay two clock 
    reg    [AW+1 :0]raddr       ;

    reg [2:0]r_cnt_reg2sram_rec_done    ;


    wire s_cnt_matrix_eqN       ;

    wire s_raddr_vld_up     ;
    wire s_raddr_vld_dw     ;
 //   wire [3:0]NUM_RADDR    ;//equal 9 or 3

    wire s_cnt_raddr_L_eq3      ;
    wire s_cnt_raddr_H_eq3      ;//for counter high 2 bit and low 2 bit

    wire  [5:0]s_pic_x_related ;
    wire  [5:0]s_pic_y_related ;
    

    wire [5:0]s_pic_x_specific          ;
    wire [5:0]s_pic_y_specific          ;

    wire s_cfsm_idle_cnn       ;//current state equal
    wire s_cfsm_full_cnn       ;
    wire s_cfsm_righ_cnn       ;
    wire s_cfsm_dow1_cnn       ;
    wire s_cfsm_left_cnn       ;
    wire s_cfsm_dow2_cnn       ;

    wire s_nfsm_idle_cnn       ;//next state equal
    wire s_nfsm_full_cnn       ;
    wire s_nfsm_righ_cnn       ;
    wire s_nfsm_dow1_cnn       ;
    wire s_nfsm_left_cnn       ;
    wire s_nfsm_dow2_cnn       ;

    

    localparam FSM_IDLE_CNN     = 7'b0000001   ;
    localparam FSM_FULL_CNN     = 7'b0000010   ;
    localparam FSM_RIGH_CNN     = 7'b0000100   ;
    localparam FSM_DOW1_CNN     = 7'b0001000   ;
    localparam FSM_LEFT_CNN     = 7'b0010000   ;
    localparam FSM_DOW2_CNN     = 7'b0100000   ;
    localparam FSM_DONE_CNN     = 7'b1000000   ;

    
    //===========================================
    // description: input signal preprocess   
    wire gen_raddr_start        ; 
 //   wire gen_raddr_sop          ;
    wire data_sop               ;
    wire [3:0]mode              ;
    wire    cnn_mode            ;
    wire    full_connect_mode   ;
    wire padding                ;
    wire  [5:0]pic_size     ;

    wire reg2sram_rec_done              ;
    wire reg_array_full         ;

    wire [AW-1 : 0] wraddr_start    ;

    assign gen_raddr_start   = gen_raddr_start_i     ;
    assign data_sop          = data_sop_i            ;
 //   assign gen_raddr_sop     = gen_raddr_sop_i       ;
    assign mode              = mode_i                ;
    assign cnn_mode          = mode[0] || mode[1] || mode[2] ;
    assign full_connect_mode = mode[3]                       ;
    assign padding           = padding_i             ;  
    assign pic_size          = pic_size_i                    ;

    assign reg2sram_rec_done         = reg2sram_rec_done_i           ;
    assign reg_array_full    = reg_array_full_i              ;

    assign wraddr_start      = wraddr_start_i                ;
    
  //  assign gen_raddr_bit     = gen_raddr_bit_i               ;
    
    

    //===========================================
    // description: output signal preprocess
    //wire [3:0] num_rdata_o  ;
    

    assign gen_raddr_end_o  = (fsm_rsram_cstate == FSM_DONE_CNN) ;
    assign raddr_vld_o  = r_raddr_vld_d2                     ;//see the design.doc
    assign reg_rst_o    = r_reg_rst                          ;
    assign raddr_o      = raddr                              ;
    assign ctrl_regnum_sel_o  = r_lut_out_d1                 ;
    assign num_rdata_o  = (s_cfsm_full_cnn) ? 4'd9 : 4'd3    ;//one time how many rdata is sent
    assign ctrl_regbit_sel_o = r_cnt_reg2sram_rec_done               ;//raddr bit 

    //===========================================
    // description: count reg2sram_rec_done ,when count eq 7, rec_matrix up ,else down
    wire s_rec_matrix        ;
    
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_cnt_reg2sram_rec_done <= 'b0  ;
        end else begin
            if (s_rec_matrix)begin
                r_cnt_reg2sram_rec_done <= 'b0  ;
            end else if (reg2sram_rec_done)begin
                r_cnt_reg2sram_rec_done <= r_cnt_reg2sram_rec_done  + 1'b1  ;
            end
        end
    end
    assign s_rec_matrix = reg2sram_rec_done &((r_cnt_reg2sram_rec_done == 3'd7) ? 1'b1 : 'b0)    ;
     //===========================================
    // description: count the rec matrix , when eq N/2N , start state change
    always @(posedge SYS_CLK or negedge SYS_NRST) begin//count the rec_matrix
        if (!SYS_NRST) begin
            r_cnt_matrix <= 'b0;
        end else begin
           // if (gen_raddr_start|| gen_raddr_sop || s_cnt_matrix_eq2N) begin//maybe no need FULL signal.//s_cnt_matrix_eq2N is for receive 1 line , gen_raddr_start is for start a new line
            if (gen_raddr_start) begin    
                r_cnt_matrix <= 'b0;
            end else if (s_rec_matrix) begin
                r_cnt_matrix <= r_cnt_matrix + 1'b1;
            end
        end
    end
    //when in mode[2] ,each line is 5 matrix when pic_size=8
    wire s_read_done                ;
    reg  [5:0]r_num_line_matrix     ;
    always @(*) begin
        if (mode[0]||mode[1])begin
            r_num_line_matrix   = (pic_size-4'd2 + padding + padding)<<1 ;
        end else if (mode[2])begin
            r_num_line_matrix   = pic_size-4'd3 + padding + padding      ;
        end else begin
            r_num_line_matrix   = 'b0   ;
        end
    end
    assign s_read_done = mode[3] ? (r_cnt_matrix * 4'd9 > pic_size) : ((r_cnt_matrix == r_num_line_matrix - 1'b1)&s_rec_matrix)  ;
    assign s_cnt_matrix_eqN  = s_rec_matrix & (r_cnt_matrix == (pic_size-4'd3 + padding + padding)) ;//for mode[1], read 1/2 line
    //===========================================
    // description: fsm state for gen raddr 
    

    always @(posedge SYS_CLK) begin
        if (!SYS_NRST) begin
            fsm_rsram_cstate <= FSM_IDLE_CNN      ;
        end else begin
            fsm_rsram_cstate <= fsm_rsram_nstate  ;
        end
    end

    always @(*) begin
        case (fsm_rsram_cstate)

        FSM_IDLE_CNN :  
            if (gen_raddr_start)begin
                fsm_rsram_nstate = FSM_FULL_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_IDLE_CNN     ;
            end

        FSM_FULL_CNN :
            if (s_rec_matrix & mode[0]) begin
                fsm_rsram_nstate = FSM_RIGH_CNN     ;
            end else if (s_rec_matrix & (mode[1]||mode[2])) begin
                fsm_rsram_nstate = FSM_DOW1_CNN     ;
            end else if (s_read_done)begin//in mode[3] , read done
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_FULL_CNN     ;
            end

        FSM_RIGH_CNN :
            if (s_read_done) begin//in mode[0] , line read done
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else if (s_rec_matrix) begin
                fsm_rsram_nstate = FSM_DOW1_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_RIGH_CNN     ;
            end

        FSM_DOW1_CNN :
            if (s_read_done) begin//in mode[1]/mode[2], line read done
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else if (s_cnt_matrix_eqN & mode[1]) begin//in mode[1], 1/2 line read done
                fsm_rsram_nstate = FSM_FULL_CNN     ;
            end else if (s_rec_matrix & mode[0]) begin
                fsm_rsram_nstate = FSM_LEFT_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_DOW1_CNN     ;
            end

        FSM_LEFT_CNN :
            if (s_read_done) begin//in mode[0], line read done
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else if (s_rec_matrix) begin
                fsm_rsram_nstate = FSM_DOW2_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_LEFT_CNN     ;
            end

        FSM_DOW2_CNN :
             if (s_rec_matrix) begin
                fsm_rsram_nstate = FSM_RIGH_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_DOW2_CNN     ;
            end

        FSM_DONE_CNN : 
                fsm_rsram_nstate = FSM_IDLE_CNN     ;

        default : fsm_rsram_nstate = FSM_IDLE_CNN   ;
        
        endcase
    end

    assign s_cfsm_idle_cnn = (fsm_rsram_cstate == FSM_IDLE_CNN) ? 1'b1 : 1'b0       ;//current state equal ...
    assign s_cfsm_full_cnn = (fsm_rsram_cstate == FSM_FULL_CNN) ? 1'b1 : 1'b0       ;
    assign s_cfsm_righ_cnn = (fsm_rsram_cstate == FSM_RIGH_CNN) ? 1'b1 : 1'b0       ;
    assign s_cfsm_dow1_cnn = (fsm_rsram_cstate == FSM_DOW1_CNN) ? 1'b1 : 1'b0       ;
    assign s_cfsm_left_cnn = (fsm_rsram_cstate == FSM_LEFT_CNN) ? 1'b1 : 1'b0       ;
    assign s_cfsm_dow2_cnn = (fsm_rsram_cstate == FSM_DOW2_CNN) ? 1'b1 : 1'b0       ;

    assign s_nfsm_idle_cnn = (fsm_rsram_nstate == FSM_IDLE_CNN) ? 1'b1 : 1'b0       ;//next state equal ..
    assign s_nfsm_full_cnn = (fsm_rsram_nstate == FSM_FULL_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_righ_cnn = (fsm_rsram_nstate == FSM_RIGH_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_dow1_cnn = (fsm_rsram_nstate == FSM_DOW1_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_left_cnn = (fsm_rsram_nstate == FSM_LEFT_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_dow2_cnn = (fsm_rsram_nstate == FSM_DOW2_CNN) ? 1'b1 : 1'b0       ; 


   

    // assign s_read_done_mode3 = (r_cnt_matrix * 4'd9 > pic_size);
    // assign s_cnt_matrix_eqN  = s_rec_matrix & (r_cnt_matrix == (pic_size-2'd2 + padding + padding) - 1'b1 - mode[2])     ;
    // assign s_cnt_matrix_eq2N = s_rec_matrix & (r_cnt_matrix == 2'd2*(pic_size-2'd2 + padding + padding) - 1'b1)   ;//when pic_size = 8, four line need read 2*(8-2) matrix
    // reg s_wait2idle    ;
    // always @(*) begin
    //     if (mode[0])begin
    //         s_wait2idle = (r_cnt_matrix == 2'd2*(pic_size-2'd2 + padding + padding))    ;
    //     end else if (mode[1])begin
    //         s_wait2idle = (r_cnt_matrix == ((pic_size-2'd2 + padding + padding))*2 )      ;
    //     end else if (mode[2])begin
    //         s_wait2idle = (r_cnt_matrix == (pic_size- 4'd3+ padding + padding))         ;
    //     end else begin
    //         s_wait2idle = 'b0 ;
    //     end
    // end
    //===========================================
    // description: PIC_X ,PIC_Y 
    //the following is one matrix discribed
    /////////////////////////////////////////////
    //(X Y  ) (X+1 Y  ) (X+2 Y  )
    //(X Y+1) (X+1 Y+1) (X+2 Y+1)
    //(X Y+2) (X+1 Y+2) (X+2 Y+2)
    /////////////////////////////////////////////
    reg               pic_x            ;
    reg        [5  :0]pic_y            ;

    reg r_pic_x_temp  ;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_pic_x_temp    <= 'b0  ;
        end else begin
            if (gen_raddr_start)begin
                r_pic_x_temp    <= 1'b1 ;
            end else if (s_rec_matrix)begin
                r_pic_x_temp    <= ~r_pic_x_temp ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            pic_x       <= 'b0            ;
            pic_y       <= 'b0            ;
        end else begin
            if (mode[0])begin
                if (gen_raddr_start)begin
                    pic_x   <= 'b0                       ;
                    pic_y   <= 'b0 - padding             ;//padding should be considered in pic_y , initial eq -2
                end else if (s_rec_matrix)begin
                    pic_x   <= pic_x + r_pic_x_temp      ;
                    pic_y   <= pic_y + (r_pic_x_temp ? 1'b0 : 1'b1)   ;
                end

            end else if(mode[1])begin
                if (gen_raddr_start)begin
                    pic_x   <=  'b0                      ;
                    pic_y   <=  'b0 - padding            ;
                end else if(s_cnt_matrix_eqN)begin
                    pic_x   <= pic_x + 1'b1              ;
                    pic_y   <=  'b0 - padding            ;
                end else if (s_rec_matrix)begin
                    pic_y   <= pic_y + 1'b1              ;
                end
                
            end else if(mode[2])begin
                if (gen_raddr_start)begin
                    pic_x   <=  'b0                      ;
                    pic_y   <=  'b0 - padding            ;
                end else if (s_rec_matrix)begin
                    pic_y   <= pic_y + 1'b1              ;
                end 
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_x_offset <= 0             ;
            r_y_offset <= 0             ;
        end else begin
            if (s_cfsm_full_cnn) begin//(x+r_cnt_raddr_L , y+r_cnt_raddr_H )
                r_x_offset <= r_cnt_raddr_L ;
                r_y_offset <= r_cnt_raddr_H ; 

            end else if ((s_cfsm_dow1_cnn||s_cfsm_dow2_cnn)) begin//(x+r_cnt_raddr_L , y+2)
                r_x_offset <= r_cnt_raddr_L ;
                r_y_offset <= 2             ;

            end else if (s_cfsm_righ_cnn) begin//(x+2 , y+r_cnt_raddr_L)
                r_x_offset <= 2             ;
                r_y_offset <= r_cnt_raddr_L ;

            end else if (s_cfsm_left_cnn) begin//(x, y+r_cnt_raddr_L)
                r_x_offset <= 0             ;
                r_y_offset <= r_cnt_raddr_L ;
            end else begin
                r_x_offset <= 0             ;
                r_y_offset <= 0             ;
            end
        end
    end

    assign s_pic_x_related = pic_x + r_x_offset      ;
    assign s_pic_y_related = pic_y + r_y_offset      ;

    assign s_pic_x_specific = s_pic_x_related + (r_cnt_gen_raddr_start - 1'b1)*2 - padding   ;
    assign s_pic_y_specific = s_pic_y_related        ;   
    
    always @(posedge SYS_CLK or negedge SYS_NRST) begin//count the number of hsync being read in sram
        if (!SYS_NRST) begin
            r_cnt_gen_raddr_start <= 'b0  ;
        end else begin
            if (data_sop) begin
                r_cnt_gen_raddr_start <= 'b0    ;
            end else if (gen_raddr_start)begin
                r_cnt_gen_raddr_start <= r_cnt_gen_raddr_start + 1'b1  ;
            end
        end
    end
            
//===========================================
// description: fsm state for gen_addr request and resopnse
reg [4  : 0]  fsm_cstate_addr    ;
reg [4  : 0]  fsm_nstate_addr    ;   

wire    s_cfsm_idle_addr    ;
wire    s_cfsm_req_addr     ;
wire    s_cfsm_gen_addr     ;
wire    s_cfsm_wait_addr    ;
wire    s_cfsm_chk_addr     ;

localparam  FSM_IDLE_ADDR   = 5'b00001      ;
localparam  FSM_REQ_ADDR    = 5'b00010      ;
localparam  FSM_CHK_ADDR    = 5'b00100      ;
localparam  FSM_GEN_ADDR    = 5'b01000      ;
localparam  FSM_WAIT_ADDR   = 5'b10000      ;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            fsm_cstate_addr <= FSM_IDLE_ADDR    ;
        end else begin
            fsm_cstate_addr <= fsm_nstate_addr  ;
        end
    end

    always @(*) begin
        case (fsm_cstate_addr)

            FSM_IDLE_ADDR   :
                if (gen_raddr_start) begin
                    fsm_nstate_addr = FSM_REQ_ADDR  ;
                end else begin
                    fsm_nstate_addr = FSM_IDLE_ADDR ;
                end

            FSM_REQ_ADDR    :
                    fsm_nstate_addr = FSM_GEN_ADDR  ;

            FSM_GEN_ADDR    :
                if (s_raddr_vld_dw) begin//when addr count done, eq 3 or 9
                    fsm_nstate_addr = FSM_CHK_ADDR  ;
                end else begin
                    fsm_nstate_addr = FSM_GEN_ADDR  ;
                end

            FSM_CHK_ADDR    :
                if (s_read_done)begin
                    fsm_nstate_addr = FSM_IDLE_ADDR ;
                end else if (reg2sram_rec_done) begin
                    fsm_nstate_addr = FSM_WAIT_ADDR ;
                end else begin
                    fsm_nstate_addr = FSM_CHK_ADDR  ;
                end
                    

            FSM_WAIT_ADDR   :
                if(~reg_array_full) begin
                    fsm_nstate_addr = FSM_REQ_ADDR  ;
                end else begin
                    fsm_nstate_addr = FSM_WAIT_ADDR ;
                end
            default : fsm_nstate_addr = FSM_IDLE_ADDR   ;
        endcase
    end

    assign  s_cfsm_idle_addr    = (fsm_cstate_addr==FSM_IDLE_ADDR)    ;
    assign  s_cfsm_req_addr     = (fsm_cstate_addr==FSM_REQ_ADDR )    ;
    assign  s_cfsm_gen_addr     = (fsm_cstate_addr==FSM_GEN_ADDR )    ;
    assign  s_cfsm_wait_addr    = (fsm_cstate_addr==FSM_WAIT_ADDR)    ;
    assign  s_cfsm_chk_addr     = (fsm_cstate_addr==FSM_CHK_ADDR )    ;


//===========================================
// description:generate counter for serial raddr number , contain two counter and one vld signal
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_cnt_raddr_L <= 'b0    ;
        end else begin
            if (s_cnt_raddr_L_eq3) begin
                r_cnt_raddr_L <= 'b0    ;
            end else if (r_raddr_vld) begin
                r_cnt_raddr_L <= r_cnt_raddr_L + 1  ;
            end
        end
    end
    assign s_cnt_raddr_L_eq3 = (r_cnt_raddr_L == 2'b10) ;

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_cnt_raddr_H <= 'b0    ;
        end else begin
            if (s_raddr_vld_dw) begin
                r_cnt_raddr_H <= 'b0    ;
            end else if (s_cnt_raddr_L_eq3) begin
                r_cnt_raddr_H <= r_cnt_raddr_H + 1  ;
            end
        end
    end
    assign s_cnt_raddr_H_eq3 = (r_cnt_raddr_H == 2'b10) & s_cnt_raddr_L_eq3 ;

   // assign NUM_RADDR    = ((fsm_rsram_cstate == FSM_FULL_CNN)||(fsm_rsram_cstate == FSM_FULL_CONNECT)) ? 4'b1010 : 4'b0010 ;//cnt eq 10 or 2
    assign s_raddr_vld_up = s_cfsm_req_addr     ;
    assign s_raddr_vld_dw = {r_cnt_raddr_H ,r_cnt_raddr_L} ==  (s_cfsm_full_cnn ? 4'b1010 : 4'b0010 )      ;
    
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_raddr_vld <= 'b0;
        end else begin
            if (s_raddr_vld_up) begin
                r_raddr_vld <= 1'b1;
            end else if (s_raddr_vld_dw) begin
                r_raddr_vld <= 'b0;
            end
        end
    end




//===========================================
// description: generate raddr signal
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_bank_status <= 3'b000 ;
        end else begin
            if (data_sop) begin
                r_bank_status <= 3'b010 ;//0 mean read mode , 1 mean write mode
            end else if (gen_raddr_start) begin
                r_bank_status <= {r_bank_status[1:0] ,r_bank_status[2]} ;//bank status change
            end
        end
    end

    ///addr realted to (x ,y)
    //ADDR[11:10] = x[1] + r_bank_status[1:0] + x[1]&r_bank_status[1]   ;
    //ADDR[9:0]   = y * 8 + bit + wraddr_start + x[0]*pic_size*8    ;

    //s_x/y_offset to raddr delay oneclock
    //s_pic_x_specific to r_reg_rst delay one clock
`ifdef  sim_gen_raddr
    wire [11:0] sim_raddr   ;
    assign sim_raddr[11:10] = (mode[3] & r_raddr_vld_d1) ? 'b0 : (s_pic_x_related[1] + r_bank_status[1:0] +  (s_pic_x_related[1]&r_bank_status[1]))   ;
    assign sim_raddr[9 : 0] = (mode[3] & r_raddr_vld_d1) ? (raddr + 1'b1) : (s_pic_y_related*8 + r_cnt_reg2sram_rec_done + wraddr_start + (s_pic_x_related[0] ? pic_size*8 : 'b0))  ;
`else
    //wire    s_pic_x_related_ad_pad   ;
    //assign  s_pic_x_related_ad_pad = s_pic_x_related + padding    ;
    reg  [3:0]r_count_reg   ;
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_count_reg <= 'b0  ;
        end else begin
            if (r_count_reg == 4'd8)begin
                r_count_reg <= 'b0  ;
            end else if (mode[3]&r_raddr_vld_d1)begin
                r_count_reg <= r_count_reg + 1'b1   ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            raddr <= 'b0    ;
            r_count_reg <= 'b0  ;
        end else begin
            if (mode[3])begin
                if (gen_raddr_start)begin
                    raddr[9:0]      <= wraddr_start     ;//for first raddr is right
                    raddr[11:10]    <= 'b0              ;
                end else if (r_raddr_vld_d1)begin
                    raddr[9:0]      <= (wraddr_start + r_cnt_reg2sram_rec_done + (r_count_reg<<3));
                    raddr[11:10]    <= 'b0              ;
                end
                
            end else begin
                raddr[9:0]      <= (s_pic_y_related<<3) + r_cnt_reg2sram_rec_done + wraddr_start + (s_pic_x_related[0] ? (pic_size<<3) : 'b0)   ;
                raddr[11:10]    <= s_pic_x_related[1] + r_bank_status[1:0] +  (s_pic_x_related[1]&r_bank_status[1])                         ;
            end
        end
    end
`endif

  //  assign raddr[9:0]   = ((fsm_rsram_cstate == FSM_FULL_CONNECT)&r_raddr_vld) ? (raddr[9:0] + 1) :(s_pic_y_related*8 + r_cnt_reg2sram_rec_done + wraddr_start + (s_pic_x_related[0] ? pic_size*8 : 'b0))   ;
   // assign raddr[11:10] = ((fsm_rsram_cstate == FSM_FULL_CONNECT)&r_raddr_vld) ? (0             ) :(s_pic_x_related[1] + r_bank_status[1:0] +  (s_pic_x_related[1]&r_bank_status[1]))             ;

//===========================================
// description: generate register_array reset signal
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST)begin
            r_raddr_vld_d1 <= 'b0   ;
            r_raddr_vld_d2 <= 'b0   ;

            r_lut_out_d1   <= 'b0   ;   
        end else begin
            r_raddr_vld_d1 <= r_raddr_vld       ;//delay one clock
            r_raddr_vld_d2 <= r_raddr_vld_d1    ;

            r_lut_out_d1   <= lut_out           ;
        end
    end

    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            r_reg_rst <= 'b0  ;
        end else begin
            if (cnn_mode)begin
                if (((s_pic_x_specific < pic_size) & (s_pic_y_specific < pic_size)) & r_raddr_vld_d1) begin//include pic_y<0 or pic_y>pic_size-1
                    r_reg_rst <= 1'b0  ;
                end else if (r_raddr_vld_d1) begin
                    r_reg_rst <= 1'b1  ;
                end
            end else begin
                if (r_count_reg + 1'b1 > pic_size)begin//no need r_raddr_vld_d1, for delay one clock
                    r_reg_rst <= 1'b1  ;
                end else begin
                    r_reg_rst <= 'b0    ;
                end
            end
            
        end
    end

    
//===========================================
// description: for ctrl_mux_1_9 siganl
`ifdef REG_SHFT
    always @(posedge SYS_CLK or negedge SYS_NRST) begin//lut change when state change
        if (!SYS_NRST) begin
            lut[0]  <= 'b0  ;
            lut[1]  <= 'b0  ;
            lut[2]  <= 'b0  ;
        end else begin
            lut[0]  <= 12'h012  ;
            lut[1]  <= 12'h345  ;
            lut[2]  <= 12'h678  ;   
        end

`else
    always @(posedge SYS_CLK or negedge SYS_NRST) begin//lut change when state change
        if (!SYS_NRST) begin
            lut[0]  <= 'b0  ;
            lut[1]  <= 'b0  ;
            lut[2]  <= 'b0  ;
        end else begin
            if (s_nfsm_righ_cnn & s_rec_matrix ) begin
                lut[0]  <= {lut[0][7:4] , lut[0][3:0] , lut[0][11:8]}   ;
                lut[1]  <= {lut[1][7:4] , lut[1][3:0] , lut[1][11:8]}   ;
                lut[2]  <= {lut[2][7:4] , lut[2][3:0] , lut[2][11:8]}   ;
            end else if (s_nfsm_left_cnn & s_rec_matrix ) begin
                lut[0]  <= {lut[0][3:0] , lut[0][11:8] , lut[0][7:4]}   ;
                lut[1]  <= {lut[1][3:0] , lut[1][11:8] , lut[1][7:4]}   ;
                lut[2]  <= {lut[2][3:0] , lut[2][11:8] , lut[2][7:4]}   ;
            end else if ((s_nfsm_dow1_cnn||s_nfsm_dow2_cnn) & s_rec_matrix) begin
                lut[0]  <= lut[1]   ;
                lut[1]  <= lut[2]   ;
                lut[2]  <= lut[0]   ;
            end else if (s_nfsm_full_cnn) begin
                lut[0]  <= 12'h012  ;
                lut[1]  <= 12'h345  ;
                lut[2]  <= 12'h678  ;
            end
        end
    end
`endif

    always @(*) begin//lut sel by lut_x and lut_y
        case(lut_y)

            2'b00   : lut_row = lut[0]  ;
            2'b01   : lut_row = lut[1]  ;
            2'b10   : lut_row = lut[2]  ;
            default : lut_row = lut[0]  ;
        endcase
    end
    always @(*) begin
        case (lut_x)
            
            2'b00   : lut_out = lut_row[11 : 8] ;
            2'b01   : lut_out = lut_row[7  : 4] ;
            2'b10   : lut_out = lut_row[3  : 0] ;
            default : lut_out = lut_row[11 : 8] ;
        endcase
    end
    always @(posedge SYS_CLK or negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            lut_x   <= 'b0  ;
            lut_y   <= 'b0  ;
        end else begin
            if (s_cfsm_full_cnn) begin//(r_cnt_raddr_L ,r_cnt_raddr_H)
                lut_x   <= r_cnt_raddr_L    ;
                lut_y   <= r_cnt_raddr_H    ;
            end else if (s_cfsm_righ_cnn) begin//(2 , r_cnt_raddr_L)
                lut_x   <= 2                ;
                lut_y   <= r_cnt_raddr_L    ;
            end else if (s_cfsm_left_cnn) begin//(0 , r_cnt_raddr_L)
                lut_x   <= 0                ;
                lut_y   <= r_cnt_raddr_L    ;
            end else if (s_cfsm_dow1_cnn||s_cfsm_dow2_cnn) begin//(r_cnt_raddr_L,2)
                lut_x   <= r_cnt_raddr_L    ;
                lut_y   <= 2                ;
            end
        end
    end
    
 //   assign ctrl_regnum_sel_o = lut_out        ;
 `ifdef sim_gen_raddr
    always @(posedge SYS_CLK) begin
        if ( s_rec_matrix)begin
            $display("\n");
        end
        if (raddr_vld_o) begin
            $display("picture position (%d , %d) in bit%d addr is bank%d ,%h",s_pic_x_specific,s_pic_y_specific,r_cnt_reg2sram_rec_done,sim_raddr[11:10],sim_raddr[9:0]);
        
        end
    end
 `endif


    
endmodule