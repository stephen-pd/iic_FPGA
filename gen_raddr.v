// +FHEADER ==================================================
// FilePath       : \sr\gen_raddr.v
// Author         : stephenpd stephenpd@163.com
// CreateDate     : 2022-08-30 10:39:36
// LastEditors    : stephenpd stephenpd@163.com
// LastEditTime   : 2022-09-17 20:50:10
// Description    : 
//                  
// 
//                  
// 
// Rev 1.0    
//                  
// 
// -FHEADER ==================================================
`define sim_gen_raddr 1
module gen_raddr #(
    parameter AW = 10    
) (
    input           SYS_CLK                     ,
    input           SYS_RST                     ,
    input           gen_raddr_hsync_i           ,//when gen_raddr_sop later , one bank full ,start to gen raddr of four lines 
    input           gen_raddr_sop_i             ,//when bank0&1 full ,start to gen raddr of four lines

    input [3    :0] mode_i                      ,//[0]three direction mode ,[1]line mode stride=1 , [2]line mode stride=2 , [3]full-connected 
    input           padding_i                   ,
    input           gen_raddr_i                 ,//reg_array receive 9/3
    input           DATA_EOP                    ,
    input           rec_rdata_matrix_i          ,//reg receive rdata of one matrix
 //   input [7:0]pic_size ,
    input [AW+1 :0] WADDR                       ,
    input [7    :0] pic_size_i                  , 
    input [2    :0] gen_raddr_bit_i             ,
    input [AW-1 :0] wraddr_start_i              ,

    input           s_reg_array_full            ,

 //   input SRAM2REG_VLD  ,//start read from sram


    output  [AW+1:0]raddr_o       ,
    output  raddr_vld_o           ,
    output  reg_rst_o             ,

    output  [3:0]NUM_RADDR      ,//how many data reg_arry should receive

    output  [3:0]ctrl_regnum_sel_o,   //for ctrl_mux_1_9
    output       r2bank_done_o 

);
    reg [7:0]r_cnt_matrix       ;//count the read_one_matrix 
    reg [7:0]fsm_rsram_cstate   ;
    reg [7:0]fsm_rsram_nstate   ;

    reg [1:0]r_cnt_raddr_L      ;
    reg [1:0]r_cnt_raddr_H      ;//raddr counter L(low 2 bit),H(high 2 bit)

 //   reg r_raddr_vld         ;//for counter enable

    reg [2:0]r_bank_status      ;//three bank status, 1 is write mode , 0 is read mode
    // reg [7:0]r_cnt_bankloop     ;//the period of bank loop 
    // reg [1:0]s_raddr_M2         ;//raddr hign two bits [11:10]

    reg [7:0]r_cnt_rline        ;//count the number of line being read

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
    reg [7 :0]r_cnt_gen_raddr_hsync ;//count gen_raddr_hsync

    reg     r_raddr_vld_d1      ;//r_raddr_vld delay one clock
    reg     r_raddr_vld_d2      ;//r_raddr_vld delay two clock 
    reg    [AW+1 :0]raddr       ;


    wire s_cnt_matrix_eqN       ;
    wire s_cnt_matrix_eq2N      ;

    wire s_cnt_raddr_vld_up     ;
    wire s_cnt_raddr_vld_dw     ;
 //   wire [3:0]NUM_RADDR    ;//equal 9 or 3

    wire s_cnt_raddr_L_eq3      ;
    wire s_cnt_raddr_H_eq3      ;//for counter high 2 bit and low 2 bit

    wire  [7:0]s_x_offset ;
    wire  [7:0]s_y_offset ;
    wire  [7:0]pic_size     ;

    wire [7:0]s_pic_x_specific          ;
    wire [7:0]s_pic_y_specific          ;

    wire s_cfsm_idle_cnn       ;//current state equal
    wire s_cfsm_full_cnn       ;
    wire s_cfsm_righ_cnn       ;
    wire s_cfsm_dow1_cnn       ;
    wire s_cfsm_left_cnn       ;
    wire s_cfsm_dow2_cnn       ;
    wire s_cfsm_full_connect_cnn    ;

    wire s_nfsm_idle_cnn       ;//next state equal
    wire s_nfsm_full_cnn       ;
    wire s_nfsm_righ_cnn       ;
    wire s_nfsm_dow1_cnn       ;
    wire s_nfsm_left_cnn       ;
    wire s_nfsm_dow2_cnn       ;

    wire [2 : 0] gen_raddr_bit  ;
    

    localparam FSM_IDLE_CNN     = 8'b00000001   ;
    localparam FSM_FULL_CNN     = 8'b00000010   ;
    localparam FSM_FULL_CONNECT = 8'b00000100   ;
    localparam FSM_RIGH_CNN     = 8'b00001000   ;
    localparam FSM_DOW1_CNN     = 8'b00010000   ;
    localparam FSM_LEFT_CNN     = 8'b00100000   ;
    localparam FSM_DOW2_CNN     = 8'b01000000   ;
    localparam FSM_DONE_CNN     = 8'b10000000   ;

    
    //===========================================
    // description: input signal preprocess   
    wire gen_raddr_hsync        ; 
    wire gen_raddr_sop          ;
    wire [3:0]mode              ;
    wire padding                ;
    wire gen_raddr              ;
    wire rec_rdata_matrix       ;

    assign gen_raddr_hsync   = gen_raddr_hsync_i     ;
    assign gen_raddr_sop     = gen_raddr_sop_i       ;
    assign mode              = mode_i                ;
    assign padding           = padding_i             ;
    assign gen_raddr         = gen_raddr_i           ;    
    assign rec_rdata_matrix  = rec_rdata_matrix_i    ;

    assign cnn_mode          = mode[0] || mode[1] || mode[2] ;
    assign full_connect_mode = mode[3]                       ;
    assign pic_size          = pic_size_i                    ;
    assign gen_raddr_bit     = gen_raddr_bit_i               ;
    assign wraddr_start      = wraddr_start_i                ;

    //===========================================
    // description: output signal preprocess

    
    assign r2bank_done_o  = (fsm_rsram_cstate == FSM_DONE_CNN) ;
    assign raddr_vld_o  = r_raddr_vld_d1                     ;
    assign reg_rst_o    = r_reg_rst                          ;
    assign raddr_o      = raddr                              ;
    assign ctrl_regnum_sel_o  = r_lut_out_d1                 ;


    //===========================================
    // description: fsm state for gen raddr 
    

    always @(posedge SYS_CLK) begin
        if (!SYS_RST) begin
            fsm_rsram_cstate <= FSM_IDLE_CNN      ;
        end else begin
            fsm_rsram_cstate <= fsm_rsram_nstate  ;
        end
    end

    always @(*) begin
        case (fsm_rsram_cstate)

        FSM_IDLE_CNN :  
            if (cnn_mode & (gen_raddr_hsync || gen_raddr_sop))begin
                fsm_rsram_nstate = FSM_FULL_CNN     ;
            end else if (full_connect_mode & DATA_EOP) begin
                fsm_rsram_nstate = FSM_FULL_CONNECT ;
            end else begin
                fsm_rsram_nstate = FSM_IDLE_CNN     ;
            end

        FSM_FULL_CNN :
            if (rec_rdata_matrix & mode[0]) begin
                fsm_rsram_nstate = FSM_RIGH_CNN     ;
            end else if (rec_rdata_matrix & (mode[1]||mode[2])) begin
                fsm_rsram_nstate = FSM_DOW1_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_FULL_CNN     ;
            end

        FSM_FULL_CONNECT :
            if (raddr == WADDR) begin//count matrix number to reg_array
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_FULL_CONNECT ;
            end

        FSM_RIGH_CNN :
            if (s_cnt_matrix_eq2N & mode[0]) begin
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else if (rec_rdata_matrix) begin
                fsm_rsram_nstate = FSM_DOW1_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_RIGH_CNN     ;
            end

        FSM_DOW1_CNN :
            if ( (s_cnt_matrix_eqN & mode[2]) || (s_cnt_matrix_eq2N & mode[1]) ) begin
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else if (s_cnt_matrix_eqN & mode[1]) begin//read one cnn line
                fsm_rsram_nstate = FSM_FULL_CNN     ;
            end else if (rec_rdata_matrix) begin
                fsm_rsram_nstate = FSM_LEFT_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_DOW1_CNN     ;
            end

        FSM_LEFT_CNN :
            if (s_cnt_matrix_eq2N & mode[0]) begin
                fsm_rsram_nstate = FSM_DONE_CNN     ;
            end else if (rec_rdata_matrix) begin
                fsm_rsram_nstate = FSM_DOW2_CNN     ;
            end else begin
                fsm_rsram_nstate = FSM_LEFT_CNN     ;
            end

        FSM_DOW2_CNN :
             if (rec_rdata_matrix) begin
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
    assign s_cfsm_full_connect_cnn = (fsm_rsram_cstate == FSM_FULL_CONNECT) ? 1'b1 : 1'b0       ;

    assign s_nfsm_idle_cnn   = (fsm_rsram_nstate == FSM_IDLE_CNN) ? 1'b1 : 1'b0       ;//next state equal ..
    assign s_nfsm_full_cnn = (fsm_rsram_nstate == FSM_FULL_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_righ_cnn = (fsm_rsram_nstate == FSM_RIGH_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_dow1_cnn = (fsm_rsram_nstate == FSM_DOW1_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_left_cnn = (fsm_rsram_nstate == FSM_LEFT_CNN) ? 1'b1 : 1'b0       ;
    assign s_nfsm_dow2_cnn = (fsm_rsram_nstate == FSM_DOW2_CNN) ? 1'b1 : 1'b0       ; 


    always @(posedge SYS_CLK or negedge SYS_RST) begin//count the rec_matrix
        if (!SYS_RST) begin
            r_cnt_matrix <= 'b0;
        end else begin
           // if (gen_raddr_hsync|| gen_raddr_sop || s_cnt_matrix_eq2N) begin//maybe no need FULL signal.//s_cnt_matrix_eq2N is for receive 1 line , gen_raddr_hsync is for start a new line
            if (gen_raddr_hsync|| gen_raddr_sop) begin    
                r_cnt_matrix <= 'b0;
            end else if (rec_rdata_matrix) begin
                r_cnt_matrix <= r_cnt_matrix + 1'b1;
            end
        end
    end
    assign s_cnt_matrix_eqN  = rec_rdata_matrix & (r_cnt_matrix == (pic_size-2) - 1)     ;
    assign s_cnt_matrix_eq2N = rec_rdata_matrix & (r_cnt_matrix == 2*(pic_size-2) - 1)   ;//when pic_size = 8, four line need read 2*(8-2) matrix

    //===========================================
    // description: PIC_X ,PIC_Y 
    //the following is one matrix discribed
    /////////////////////////////////////////////
    //(X Y  ) (X+1 Y  ) (X+2 Y  )
    //(X Y+1) (X+1 Y+1) (X+2 Y+1)
    //(X Y+2) (X+1 Y+2) (X+2 Y+2)
    /////////////////////////////////////////////
    reg         [1  :0]pic_x_temp       ;
    reg         [8  :0]pic_y_temp       ;//the coordinate of cnn in picture,ignore the last bit
    wire               pic_x            ;
    wire        [7  :0]pic_y            ;

    assign  pic_x   = pic_x_temp[1]     ;
    assign  pic_y   = pic_y_temp[8:1]   ;
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            pic_x_temp <= 'b0            ;
            pic_y_temp <= 'b0            ;
        end else begin
            if (mode[0])begin
                if (gen_raddr_sop || gen_raddr_hsync)begin
                    pic_x_temp <= 2'b01             ;
                    pic_y_temp <=  'b0              ;
                end else if (rec_rdata_matrix)begin
                    pic_x_temp <= pic_x_temp + 1'b1 ;
                    pic_y_temp <= pic_y_temp + 1'b1 ;
                end

            end else if(mode[1])begin
                if (gen_raddr_sop || gen_raddr_hsync)begin
                    pic_x_temp <=  'b0              ;
                    pic_y_temp <=  'b0              ;
                end else if(s_cnt_matrix_eqN)begin
                    pic_x_temp <= pic_x_temp + 2'b10 ;
                end else if (rec_rdata_matrix)begin
                    pic_y_temp <= pic_y_temp + 2'b10 ;
                end
                
            end else if(mode[2])begin
                if (gen_raddr_sop || gen_raddr_hsync)begin
                    pic_x_temp <=  'b0              ;
                    pic_y_temp <=  'b0              ;
                end else if (rec_rdata_matrix)begin
                    pic_y_temp <= pic_y_temp + 2'b10 ;
                end 
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
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

    assign s_x_offset = pic_x + r_x_offset      ;
    assign s_y_offset = pic_y + r_y_offset      ;

    assign s_pic_x_specific = s_x_offset + r_cnt_gen_raddr_hsync*4 - padding  ;
    assign s_pic_y_specific = s_y_offset - padding  ;
            
    // always @(posedge SYS_CLK or negedge SYS_RST) begin
    //     if (!SYS_RST) begin
    //         X <= 'b0            ;
    //         Y <= 'b0            ;
    //     end else begin
    //         if (gen_raddr_sop) begin//the start of picture
    //             X <= 'b0            ;
    //             Y <= 0 - padding    ;
    //         end else if ((fsm_rsram_nstate==FSM_FULL_CNN) & gen_raddr_hsync & (mode[0] || mode[2])) begin//bank status change in line mode(stride=2) and three directions mode
    //             X <= 'b0            ;
    //             Y <= 0 - padding    ;
    //         end else if ((fsm_rsram_nstate==FSM_FULL_CNN) & gen_raddr_hsync & mode[1]) begin//bank status change in line mode(stride=1)
    //             X <= X + 1          ;
    //             Y <= 0 - padding    ;
    //         end else if ((fsm_rsram_nstate==FSM_FULL_CNN) & s_cnt_matrix_eqN & mode[1]) begin//read another line in line mode(stride=1)
    //             X <= X + 1          ;
    //             Y <= 0 - padding    ;
    //         end else if (((fsm_rsram_nstate==FSM_DOW1_CNN)||((fsm_rsram_nstate==FSM_DOW2_CNN))) & rec_rdata_matrix) begin
    //             X <= X              ;
    //             Y <= Y + 1          ;
    //         end else if ((fsm_rsram_nstate==FSM_RIGH_CNN) & rec_rdata_matrix) begin
    //             X <= X + 1          ;
    //             Y <= Y              ;
    //         end else if ((fsm_rsram_nstate==FSM_LEFT_CNN) & rec_rdata_matrix) begin
    //             X <= X - 1          ;
    //             Y <= Y              ;
    //         end 
    //     end
    // end
    /////////////////////////////

// wire signed[7:0]temp1     ;
// wire [7:0]temp2     ;
// wire temp3                 ;
// wire  temp4             ;
// wire temp5              ;
// wire temp6              ;
// wire temp7              ;
// assign temp1 = 'b0 - padding     ;
// assign temp2 = 'b0 - padding     ;
// assign temp3 = (temp1 < pic_size) ? 1'b1 : 'b0  ;
// assign temp7 = (temp1 < 0) ? 1'b1 : 'b0  ;
// assign temp4 = (temp2< pic_size) ? 1'b1 : 'b0   ;
// assign temp5 = (('b0 - padding)<pic_size)? 1'b1 : 'b0 ;
//===========================================
// description:generate counter for serial raddr number , contain two counter and one vld signal
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_cnt_raddr_L <= 'b0    ;
        end else begin
            if (r_raddr_vld & s_cnt_raddr_L_eq3) begin
                r_cnt_raddr_L <= 'b0    ;
            end else if (r_raddr_vld) begin
                r_cnt_raddr_L <= r_cnt_raddr_L + 1  ;
            end
        end
    end
    assign s_cnt_raddr_L_eq3 = (r_cnt_raddr_L == 2'b10) ;

    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_cnt_raddr_H <= 'b0    ;
        end else begin
            if (s_cnt_raddr_vld_dw) begin
                r_cnt_raddr_H <= 'b0    ;
            end else if (r_raddr_vld & s_cnt_raddr_L_eq3) begin
                r_cnt_raddr_H <= r_cnt_raddr_H + 1  ;
            end
        end
    end
    assign s_cnt_raddr_H_eq3 = (r_cnt_raddr_H == 2'b10) & s_cnt_raddr_L_eq3 ;

    assign NUM_RADDR    = ((fsm_rsram_cstate == FSM_FULL_CNN)||(fsm_rsram_cstate == FSM_FULL_CONNECT)) ? 4'b1010 : 4'b0010 ;//cnt eq 10 or 2
    assign s_cnt_raddr_vld_up = gen_raddr_sop | gen_raddr_hsync | gen_raddr     ;
    assign s_cnt_raddr_vld_dw = {r_cnt_raddr_H ,r_cnt_raddr_L} == NUM_RADDR    ;
    
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST)begin
            r_raddr_vld <= 'b0;
        end else begin
            if (s_cnt_raddr_vld_up) begin
                r_raddr_vld <= 1'b1;
            end else if (s_cnt_raddr_vld_dw) begin
                r_raddr_vld <= 'b0;
            end
        end
    end


//===========================================
// description: generate raddr signal

    

    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_bank_status <= 3'b000 ;
        end else begin
            if (gen_raddr_sop) begin
                r_bank_status <= 3'b100 ;//0 mean read mode , 1 mean write mode
            end else if (gen_raddr_hsync) begin
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
    assign sim_raddr[11:10] = (s_cfsm_full_connect_cnn & r_raddr_vld_d1) ? 'b0 : (s_x_offset[1] + r_bank_status[1:0] +  (s_x_offset[1]&r_bank_status[1]))   ;
    assign sim_raddr[9 : 0] = (s_cfsm_full_connect_cnn & r_raddr_vld_d1) ? (raddr + 1'b1) : (s_y_offset*8 + gen_raddr_bit + wraddr_start + (s_x_offset[0] ? pic_size*8 : 'b0))  ;
`else
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            raddr <= 'b0    ;
        end else begin
            if (s_cfsm_full_connect_cnn & r_raddr_vld_d1)begin
                raddr[9:0]      <= raddr + 1'b1     ;
                raddr[11:10]    <= 'b0              ;
            end else begin
                raddr[9:0]      <= s_y_offset*8 + gen_raddr_bit + wraddr_start + (s_x_offset[0] ? pic_size*8 : 'b0) ;
                raddr[11:10]    <= s_x_offset[1] + r_bank_status[1:0] +  (s_x_offset[1]&r_bank_status[1])           ;
            end
        end
    end
`endif

  //  assign raddr[9:0]   = ((fsm_rsram_cstate == FSM_FULL_CONNECT)&r_raddr_vld) ? (raddr[9:0] + 1) :(s_y_offset*8 + gen_raddr_bit + wraddr_start + (s_x_offset[0] ? pic_size*8 : 'b0))   ;
   // assign raddr[11:10] = ((fsm_rsram_cstate == FSM_FULL_CONNECT)&r_raddr_vld) ? (0             ) :(s_x_offset[1] + r_bank_status[1:0] +  (s_x_offset[1]&r_bank_status[1]))             ;

//===========================================
// description: generate register_array reset signal
    // always @(posedge SYS_CLK or negedge SYS_RST) begin
    //     if (!SYS_RST) begin
    //         r_reg_rst <= 'b0  ;
    //     end else begin
    //         if ( (r_cnt_rline == 4)&(s_x_offset == 'b0)  ||  (r_cnt_rline == pic_size)&(s_x_offset == 3) || (r_y_offset>(pic_size-1)) || (r_y_offset<0) ) begin
    //             r_reg_rst <= 'b1  ;
    //         end else begin
    //             r_reg_rst <= 'b0  ;
    //         end
    //     end
    // end

    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST)begin
            r_raddr_vld_d1 <= 'b0   ;
            r_raddr_vld_d2 <= 'b0   ;

            r_lut_out_d1   <= 'b0   ;   
        end else begin
            r_raddr_vld_d1 <= r_raddr_vld       ;//delay one clock
            r_raddr_vld_d2 <= r_raddr_vld_d1    ;

            r_lut_out_d1   <= lut_out           ;
        end
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
            r_reg_rst <= 'b0  ;
        end else begin
            if (( (s_pic_x_specific > (pic_size-1)) || (s_y_offset > (pic_size-1)) )&r_raddr_vld_d1) begin//include pic_y<0 or pic_y>pic_size-1
                r_reg_rst <= 1'b1  ;
            end else if (r_raddr_vld_d1) begin
                r_reg_rst <= 1'b0  ;
            end
        end
    end

    always @(posedge SYS_CLK or negedge SYS_RST) begin//count the number of hsync being read in sram
        if (!SYS_RST) begin
            r_cnt_gen_raddr_hsync <= 'b0  ;
        end else begin
            if (gen_raddr_sop) begin
                r_cnt_gen_raddr_hsync <= 'b0    ;
            end else if (gen_raddr_hsync)begin
                r_cnt_gen_raddr_hsync <= r_cnt_gen_raddr_hsync + 1'b1  ;
            end
        end
    end
    
//===========================================
// description: for ctrl_mux_1_9 siganl
`ifdef REG_SHFT
    always @(posedge SYS_CLK or negedge SYS_RST) begin//lut change when state change
        if (!SYS_RST) begin
            lut[0]  <= 'b0  ;
            lut[1]  <= 'b0  ;
            lut[2]  <= 'b0  ;
        end else begin
            lut[0]  <= 12'h012  ;
            lut[1]  <= 12'h345  ;
            lut[2]  <= 12'h678  ;   
        end

`else
    always @(posedge SYS_CLK or negedge SYS_RST) begin//lut change when state change
        if (!SYS_RST) begin
            lut[0]  <= 12'h012  ;
            lut[1]  <= 12'h345  ;
            lut[2]  <= 12'h678  ;
        end else begin
            if (s_nfsm_righ_cnn & rec_rdata_matrix ) begin
                lut[0]  <= {lut[0][7:4] , lut[0][3:0] , lut[0][11:8]}   ;
                lut[1]  <= {lut[1][7:4] , lut[1][3:0] , lut[1][11:8]}   ;
                lut[2]  <= {lut[2][7:4] , lut[2][3:0] , lut[2][11:8]}   ;
            end else if (s_nfsm_left_cnn & rec_rdata_matrix ) begin
                lut[0]  <= {lut[0][3:0] , lut[0][11:8] , lut[0][7:4]}   ;
                lut[1]  <= {lut[1][3:0] , lut[1][11:8] , lut[1][7:4]}   ;
                lut[2]  <= {lut[2][3:0] , lut[2][11:8] , lut[2][7:4]}   ;
            end else if ((s_nfsm_dow1_cnn||s_nfsm_dow2_cnn) & rec_rdata_matrix) begin
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
    always @(posedge SYS_CLK or negedge SYS_RST) begin
        if (!SYS_RST) begin
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
        if (raddr_vld_o) begin
            $display("picture position (%d , %d) in bit%d addr is bank%d ,%h",s_pic_x_specific,s_pic_y_specific,gen_raddr_bit,sim_raddr[11:10],sim_raddr[9:0]);
        
        end
    end
 `endif


    
endmodule